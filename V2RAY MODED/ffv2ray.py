#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
visibleTech V2Ray (Xray) manager   -   VMess / VLESS / Trojan  (WS + gRPC)

  * keeps the accounts (users.json) and the live traffic counters (usage.json)
  * renders the Xray config and the nginx front config from those files
  * `daemon` polls the Xray stats API, counts bandwidth per user, and takes a
    user out of the config when the total/daily quota or the expiry is reached
  * works on Python 3.6+  (Ubuntu 18.04 - 26.04, all Debian)

Layout (all of it can be moved with the FFV2_DIR environment variable):
  /etc/visibleTech/v2ray/{settings.json,users.json,usage.json,config.json,nginx.conf}
"""
FFV2RAY_API = 3

import argparse
import base64
import contextlib
import fcntl
import json
import os
import pwd
import re
import shutil
import subprocess
import sys
import time
import urllib.parse
import uuid

V2_DIR = os.environ.get('FFV2_DIR', '/etc/visibleTech/v2ray')
SETTINGS_FILE = os.path.join(V2_DIR, 'settings.json')
USERS_FILE = os.path.join(V2_DIR, 'users.json')
USAGE_FILE = os.path.join(V2_DIR, 'usage.json')
XRAY_CONF = os.path.join(V2_DIR, 'config.json')
NGINX_CONF = os.path.join(V2_DIR, 'nginx.conf')
SITE_DIR = os.environ.get('FFV2_SITE_DIR', '/var/www/visibleTech-site')
ACCESS_LOG = os.environ.get('FFV2_ACCESS_LOG', '/var/log/xray/access.log')
XRAY_SERVICE = 'ff-xray'
NGINX_SERVICE = 'ff-v2ray-nginx'
GB = 1073741824
INTERVAL = 3          # seconds between two stats polls of the daemon
LIMITS_FILE = os.path.join(V2_DIR, 'limits.json')
DEVICE_WINDOW = 120   # a device (source IP) counts as online if it connected in the last N seconds
BLOCK_SECONDS = 120   # an extra device over the account's limit is refused for this long
LOCAL_IPS = ('127.0.0.1', '::1', '')

PROTO_ORDER = ['vmess', 'vless', 'trojan']
PROTOS = {
    'vmess':  {'label': 'Vmess',  'path': '/vmess',     'grpc': 'vmess-grpc',  'port': 10001, 'gport': 10011},
    'vless':  {'label': 'Vless',  'path': '/vless',     'grpc': 'vless-grpc',  'port': 10002, 'gport': 10012},
    'trojan': {'label': 'Trojan', 'path': '/trojan-ws', 'grpc': 'trojan-grpc', 'port': 10003, 'gport': 10013},
}

DEFAULTS = {
    'domain': '',
    'tls_port': 443,
    'http_port': 80,
    'cert': '/etc/visibleTech/ssl/visibleTech.crt',
    'key': '/etc/visibleTech/ssl/visibleTech.key',
    'xray_bin': '/usr/local/lib/visibleTech-v2ray/xray',
    'nginx_bin': '/usr/sbin/nginx',
    'api_port': 10085,
    # client config options ("bug host" technique): connect address, TLS SNI and WS Host header
    'cfg_address': '',
    'cfg_sni': '',
    'cfg_host': '',
    'fake_site': '',     # decoy website template served on '/' ('' = off)
    'decoy_port': 0,     # >0: the port multiplexer owns 80/443, nginx only serves the decoy on 127.0.0.1:<port>
}

NAME_RE = re.compile(r'^[A-Za-z0-9_-]{2,24}$')
ID_RE = re.compile(r'^[A-Za-z0-9._-]{3,30}$')   # custom short id (Xray turns non-UUID ids into a UUID itself)
HOST_RE = re.compile(r'^[A-Za-z0-9.-]{1,253}$')


# ------------------------------------------------------------------ colors
class C(object):
    on = sys.stdout.isatty() and not os.environ.get('NO_COLOR')

    @staticmethod
    def c(code, text):
        text = str(text)
        return '\033[%sm%s\033[0m' % (code, text) if C.on else text


def grn(s): return C.c('0;32', s)
def red(s): return C.c('0;31', s)
def yel(s): return C.c('1;33', s)
def cyn(s): return C.c('0;36', s)
def org(s): return C.c('0;33', s)
def wht(s): return C.c('1;37', s)
def dim(s): return C.c('2', s)


def die(msg, code=1):
    sys.stderr.write(red('Error: ' + msg) + '\n')
    sys.exit(code)


# ------------------------------------------------------------------ files / lock
_lock_fd = None
_lock_depth = 0


@contextlib.contextmanager
def locked():
    global _lock_fd, _lock_depth
    if _lock_depth == 0:
        os.makedirs(V2_DIR, exist_ok=True)
        _lock_fd = open(os.path.join(V2_DIR, '.lock'), 'a+')
        fcntl.flock(_lock_fd, fcntl.LOCK_EX)
    _lock_depth += 1
    try:
        yield
    finally:
        _lock_depth -= 1
        if _lock_depth == 0:
            fcntl.flock(_lock_fd, fcntl.LOCK_UN)
            _lock_fd.close()
            _lock_fd = None


def read_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (IOError, OSError, ValueError):
        return default


def write_text(path, text, mode=0o600):
    tmp = path + '.tmp'
    with open(tmp, 'w') as f:
        f.write(text)
        f.flush()
        os.fsync(f.fileno())
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def write_json(path, data, mode=0o600):
    write_text(path, json.dumps(data, indent=1, sort_keys=True) + '\n', mode)


def read_text(path):
    try:
        with open(path) as f:
            return f.read()
    except (IOError, OSError):
        return None


def load_settings():
    s = dict(DEFAULTS)
    s.update(read_json(SETTINGS_FILE, {}))
    return s


def load_users():
    return read_json(USERS_FILE, {})


def save_users(users):
    write_json(USERS_FILE, users)


def load_usage():
    u = read_json(USAGE_FILE, {})
    if not isinstance(u, dict):
        u = {}
    u.setdefault('users', {})
    u.setdefault('ts', 0)
    return u


def save_usage(usage, users=None):
    if users is not None:
        for name in list(usage['users'].keys()):
            if name not in users:
                del usage['users'][name]
    write_json(USAGE_FILE, usage)


def load_limits():
    d = read_json(LIMITS_FILE, {})
    if not isinstance(d, dict):
        d = {}
    d.setdefault('devices', {})
    d.setdefault('blocks', {})
    return d


def save_limits(d):
    write_json(LIMITS_FILE, d)


def user_conn_limit(u):
    """Max devices for an account. 0 = unlimited (also for old accounts without the field)."""
    try:
        return max(0, int(u.get('conn_limit', 0)))
    except (TypeError, ValueError):
        return 0


def run(cmd, timeout=60):
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           universal_newlines=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except Exception as exc:                       # missing binary, timeout ...
        return 127, '', str(exc)


# ------------------------------------------------------------------ formatting
def human(n):
    n = float(n)
    for unit in ('B', 'KB', 'MB', 'GB', 'TB'):
        if n < 1024 or unit == 'TB':
            return ('%d %s' % (n, unit)) if unit == 'B' else ('%.2f %s' % (n, unit))
        n /= 1024.0


def human_rate(n):
    return human(n) + '/s'


def gb_str(gb):
    gb = float(gb)
    return ('%d' % gb) if gb == int(gb) else ('%g' % gb)


def fmt_time(ts):
    return time.strftime('%Y-%m-%d %H:%M', time.localtime(ts))


def today_str(now):
    return time.strftime('%Y-%m-%d', time.localtime(now))


def quota_bytes(gb):
    try:
        return int(float(gb) * GB)
    except (TypeError, ValueError):
        return 0


def new_usage(now):
    return {'total': 0, 'daily': 0, 'day': today_str(now), 'up': 0, 'down': 0,
            'rate_up': 0, 'rate_down': 0, 'last': 0}


def user_status(u, usg, now):
    if u.get('locked'):
        return 'locked'
    if u.get('expiry') and now >= u['expiry']:
        return 'expired'
    tl = quota_bytes(u.get('total_gb', 0))
    if tl > 0 and usg.get('total', 0) >= tl:
        return 'quota'
    dl = quota_bytes(u.get('daily_gb', 0))
    if dl > 0 and usg.get('daily', 0) >= dl:
        return 'daily'
    return 'active'


STATUS_TEXT = {
    'active': ('Active', grn), 'locked': ('Locked', yel), 'expired': ('Expired', red),
    'quota': ('Quota Full', red), 'daily': ('Daily Full', red),
}


def status_label(status):
    text, color = STATUS_TEXT.get(status, (status, wht))
    return color(text)


def usage_text(u, usg):
    tl = u.get('total_gb', 0)
    dl = u.get('daily_gb', 0)
    parts = []
    parts.append('%s/%sG' % (('%.1f' % (usg.get('total', 0) / float(GB))), gb_str(tl)) if float(tl) > 0
                 else '%s/inf' % human(usg.get('total', 0)).replace(' ', ''))
    if float(dl) > 0:
        parts.append('%s/%sG/d' % (('%.1f' % (usg.get('daily', 0) / float(GB))), gb_str(dl)))
    return ' | '.join(parts)


# ------------------------------------------------------------------ xray / nginx rendering
def active_clients(users, usage, now):
    result = {p: [] for p in PROTO_ORDER}
    for name in sorted(users):
        u = users[name]
        usg = usage['users'].get(name, {})
        if user_status(u, usg, now) != 'active':
            continue
        p = u['proto']
        if p == 'trojan':
            result[p].append({'password': u['id'], 'email': name})
        else:
            result[p].append({'id': u['id'], 'email': name})
    return result


def block_rules(users, now):
    """Routing rules that refuse the extra devices of accounts that are over their device limit."""
    rules = []
    blocks = load_limits().get('blocks', {})
    for name in sorted(blocks):
        if name not in users or user_conn_limit(users[name]) <= 0:
            continue
        ips = sorted(ip for ip, until in blocks[name].items() if until > now)
        if ips:
            rules.append({'type': 'field', 'user': [name], 'source': ips, 'outboundTag': 'blocked'})
    return rules


def render_xray(st, users, usage, now):
    clients = active_clients(users, usage, now)
    inbounds = [{
        'tag': 'api', 'listen': '127.0.0.1', 'port': int(st['api_port']),
        'protocol': 'dokodemo-door', 'settings': {'address': '127.0.0.1'},
    }]
    for proto in PROTO_ORDER:
        if not clients[proto]:
            continue
        p = PROTOS[proto]
        settings = {'clients': clients[proto]}
        if proto == 'vless':
            settings['decryption'] = 'none'
        inbounds.append({
            'tag': proto + '-ws', 'listen': '127.0.0.1', 'port': p['port'], 'protocol': proto,
            'settings': settings,
            'streamSettings': {'network': 'ws', 'security': 'none', 'wsSettings': {'path': p['path']}},
        })
        inbounds.append({
            'tag': proto + '-grpc', 'listen': '127.0.0.1', 'port': p['gport'], 'protocol': proto,
            'settings': settings,
            'streamSettings': {'network': 'grpc', 'security': 'none',
                               'grpcSettings': {'serviceName': p['grpc']}},
        })
    return {
        'log': {'access': ACCESS_LOG, 'error': '/var/log/xray/error.log', 'loglevel': 'warning'},
        'api': {'tag': 'api', 'services': ['StatsService']},
        'stats': {},
        'policy': {'levels': {'0': {'statsUserUplink': True, 'statsUserDownlink': True}}},
        'inbounds': inbounds,
        'outbounds': [{'protocol': 'freedom', 'tag': 'direct'},
                      {'protocol': 'blackhole', 'tag': 'blocked'}],
        'routing': {'rules': [
            {'type': 'field', 'inboundTag': ['api'], 'outboundTag': 'api'},
        ] + block_rules(users, now) + [
            {'type': 'field', 'outboundTag': 'blocked',
             'ip': ['127.0.0.0/8', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16',
                    '169.254.0.0/16', '::1/128', 'fc00::/7', 'fe80::/10']},
        ]},
    }


# ------------------------------------------------------------------ fake website (decoy for the domain)
SITE_TEMPLATES = ('business', 'cloud', 'blog')


def _site_brand(domain):
    parts = [x for x in (domain or '').split('.') if x]
    label = parts[-2] if len(parts) >= 2 else (parts[0] if parts else 'Example')
    label = re.sub(r'[^A-Za-z0-9]+', ' ', label).strip() or 'Example'
    return label.title()


def _site_page(tpl, brand, domain, title, body, active):
    import html as _h
    brand_e, domain_e = _h.escape(brand), _h.escape(domain)
    themes = {
        'business': ('#1d4ed8', '#f8fafc', '#0f172a', '#ffffff', 'system-ui,Segoe UI,Arial,sans-serif'),
        'cloud':    ('#0d9488', '#0b1220', '#e2e8f0', '#111a2e', 'system-ui,Segoe UI,Arial,sans-serif'),
        'blog':     ('#9a3412', '#fffbf5', '#292524', '#ffffff', 'Georgia,Times New Roman,serif'),
    }
    accent, bg, fg, card, font = themes[tpl]
    suffix = {'business': 'Digital Solutions', 'cloud': 'Cloud', 'blog': 'Journal'}[tpl]
    nav = ''.join('<a href="%s"%s>%s</a>' % (href, ' class="on"' if key == active else '', label)
                  for key, href, label in (('home', '/', 'Home'), ('about', '/about.html', 'About'),
                                           ('contact', '/contact.html', 'Contact')))
    css = ('*{box-sizing:border-box}body{margin:0;background:%(bg)s;color:%(fg)s;font-family:%(font)s;line-height:1.6}'
           'header{background:%(card)s;border-bottom:1px solid rgba(128,128,128,.25)}'
           '.w{max-width:960px;margin:0 auto;padding:0 20px}.bar{display:flex;justify-content:space-between;align-items:center;padding:16px 0}'
           '.logo{font-weight:700;font-size:1.15rem;color:%(accent)s}nav a{margin-left:18px;color:%(fg)s;text-decoration:none;opacity:.8}'
           'nav a.on,nav a:hover{color:%(accent)s;opacity:1}.hero{padding:70px 0 40px}.hero h1{font-size:2.2rem;margin:0 0 12px}'
           '.hero p{max-width:620px;opacity:.85}.btn{display:inline-block;margin-top:16px;padding:10px 20px;background:%(accent)s;color:#fff;'
           'text-decoration:none;border-radius:6px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:18px;padding:20px 0 50px}'
           '.c{background:%(card)s;border:1px solid rgba(128,128,128,.25);border-radius:10px;padding:20px}.c h3{margin:0 0 8px;color:%(accent)s}'
           'main{padding:40px 0}footer{border-top:1px solid rgba(128,128,128,.25);padding:22px 0;font-size:.85rem;opacity:.7}'
           % {'bg': bg, 'fg': fg, 'font': font, 'card': card, 'accent': accent})
    return ('<!DOCTYPE html>\n<html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>%s - %s %s</title><style>%s</style></head><body>'
            '<header><div class="w bar"><span class="logo">%s %s</span><nav>%s</nav></div></header>'
            '%s<footer><div class="w">&copy; 2026 %s %s &middot; %s</div></footer></body></html>\n'
            % (_h.escape(title), brand_e, suffix, css, brand_e, suffix, nav, body, brand_e, suffix, domain_e))


def _site_files(tpl, domain):
    import html as _h
    brand = _site_brand(domain)
    be = _h.escape(brand)
    de = _h.escape(domain)
    if tpl == 'business':
        hero = ('<div class="hero"><h1>Reliable IT services for growing companies</h1>'
                '<p>%s helps small and medium businesses run smoothly with practical, well-documented technology support.</p>'
                '<a class="btn" href="/contact.html">Talk to us</a></div>' % be)
        cards = [('Managed IT support', 'Day-to-day help desk, device management and updates so your team can stay productive.'),
                 ('Cloud migration', 'Move email, files and line-of-business apps to the cloud with a clear plan and minimal downtime.'),
                 ('Network and security', 'Reviews of your network, backups and access controls with plain-language recommendations.')]
        about = ('About us', '%s is a small team of engineers and support specialists. We prefer simple setups, clear documentation and honest advice.' % be)
    elif tpl == 'cloud':
        hero = ('<div class="hero"><h1>Simple cloud hosting and storage</h1>'
                '<p>%s offers straightforward virtual servers and file storage for projects of any size. No surprises, no long contracts.</p>'
                '<a class="btn" href="/contact.html">Get in touch</a></div>' % be)
        cards = [('Virtual servers', 'Fast SSD-backed machines in several regions, ready in minutes.'),
                 ('Object storage', 'Store and share files with versioning and simple access rules.'),
                 ('Daily backups', 'Automatic snapshots so you can roll back when you need to.')]
        about = ('About the platform', '%s is run by a small infrastructure team focused on reliability and clear pricing.' % be)
    else:
        hero = ('<div class="hero"><h1>Notes on technology and travel</h1>'
                '<p>%s is a personal journal: short write-ups on gadgets, software I use, and places worth visiting.</p>'
                '<a class="btn" href="/about.html">About this journal</a></div>' % be)
        cards = [('Setting up a home network', 'What worked, what did not, and the cheap upgrades that made the biggest difference.'),
                 ('A week with a mechanical keyboard', 'First impressions, typing feel and whether the noise is worth it.'),
                 ('Weekend trip notes', 'Routes, small cafes and a few lessons learned about packing light.')]
        about = ('About this journal', '%s is written by one person in their spare time. New posts appear whenever there is something worth sharing.' % be)
    grid = '<div class="grid">%s</div>' % ''.join('<div class="c"><h3>%s</h3><p>%s</p></div>' % (_h.escape(t), _h.escape(d)) for t, d in cards)
    pages = {
        'index.html': _site_page(tpl, brand, domain, 'Home', '<div class="w">%s%s</div>' % (hero, grid), 'home'),
        'about.html': _site_page(tpl, brand, domain, 'About', '<main><div class="w"><h1>%s</h1><p>%s</p></div></main>' % (_h.escape(about[0]), _h.escape(about[1])), 'about'),
        'contact.html': _site_page(tpl, brand, domain, 'Contact', '<main><div class="w"><h1>Contact</h1><p>Questions are welcome. Send us an email at <b>info@%s</b> and we will reply as soon as we can.</p></div></main>' % de, 'contact'),
        '404.html': _site_page(tpl, brand, domain, 'Page not found', '<main><div class="w"><h1>404 - Page not found</h1><p>The page you are looking for does not exist. <a href="/">Back to the home page</a>.</p></div></main>', ''),
        'robots.txt': 'User-agent: *\nAllow: /\n',
    }
    return pages


def write_site(tpl, domain):
    shutil.rmtree(SITE_DIR, ignore_errors=True)
    os.makedirs(SITE_DIR, 0o755)
    os.chmod(SITE_DIR, 0o755)
    for name, content in _site_files(tpl, domain).items():
        path = os.path.join(SITE_DIR, name)
        with open(path, 'w') as f:
            f.write(content)
        os.chmod(path, 0o644)


def cmd_fakesite(a):
    """Install / remove / show the decoy website served by the V2Ray front nginx on '/'."""
    st = need_installed()
    with locked():
        st = load_settings()
        if a.off:
            st['fake_site'] = ''
            write_json(SETTINGS_FILE, st)
            apply_all()
            shutil.rmtree(SITE_DIR, ignore_errors=True)
        elif a.template:
            if a.template not in SITE_TEMPLATES:
                die('Unknown template. Choose: %s' % ', '.join(SITE_TEMPLATES))
            write_site(a.template, st['domain'])
            st['fake_site'] = a.template
            write_json(SETTINGS_FILE, st)
            apply_all()
    st = load_settings()
    print(json.dumps({'template': st.get('fake_site', ''), 'enabled': bool(st.get('fake_site')),
                      'templates': list(SITE_TEMPLATES), 'dir': SITE_DIR}))


def render_nginx(st):
    ipv6 = os.path.exists('/proc/net/if_inet6')
    try:
        pwd.getpwnam('www-data')
        user_line = 'user www-data;\n'
    except KeyError:
        user_line = ''

    def locations():
        out = []
        for proto in PROTO_ORDER:
            p = PROTOS[proto]
            out.append(
                '    location %(path)s {\n'
                '        proxy_pass http://127.0.0.1:%(port)d;\n'
                '        proxy_http_version 1.1;\n'
                '        proxy_set_header Upgrade $http_upgrade;\n'
                '        proxy_set_header Connection $connection_upgrade;\n'
                '        proxy_set_header Host $host;\n'
                '        proxy_set_header X-Real-IP $remote_addr;\n'
                '        proxy_set_header X-Forwarded-For $remote_addr;\n'
                '        proxy_read_timeout 86400s;\n'
                '        proxy_send_timeout 86400s;\n'
                '        proxy_buffering off;\n'
                '    }\n' % {'path': p['path'], 'port': p['port']})
        return ''.join(out)

    def grpc_locations():
        out = []
        for proto in PROTO_ORDER:
            p = PROTOS[proto]
            out.append(
                '    location /%(svc)s {\n'
                '        grpc_pass grpc://127.0.0.1:%(port)d;\n'
                '        grpc_read_timeout 1h;\n'
                '        grpc_send_timeout 1h;\n'
                '        client_body_timeout 1h;\n'
                '        client_max_body_size 0;\n'
                '        grpc_set_header Host $host;\n'
                '        grpc_set_header X-Real-IP $remote_addr;\n'
                '        grpc_set_header X-Forwarded-For $remote_addr;\n'
                '    }\n' % {'svc': p['grpc'], 'port': p['gport']})
        return ''.join(out)

    if st.get('fake_site') and os.path.isdir(SITE_DIR):
        fallback = ('    root %s;\n    index index.html;\n    error_page 404 /404.html;\n'
                    '    location / { try_files $uri $uri/ =404; }\n'
                    '    location = /404.html { internal; }\n' % SITE_DIR)
    else:
        fallback = '    location / { return 404; }\n'

    decoy_port = int(st.get('decoy_port') or 0)
    if decoy_port:
        # HAProxy (port multiplexer) owns 80/443 and sends browsers here: serve only the fake site, on loopback
        return ('# generated by ffv2ray.py - do not edit, changes are overwritten\n'
                + user_line +
                'worker_processes 1;\n'
                'pid /run/ff-v2ray-nginx.pid;\n'
                'error_log /var/log/xray/nginx-error.log warn;\n'
                'events { worker_connections 1024; }\n'
                'http {\n'
                '  access_log off;\n'
                '  server_tokens off;\n'
                '  server {\n'
                '    listen 127.0.0.1:%d default_server;\n'
                '    server_name _;\n'
                '%s'
                '  }\n'
                '}\n') % (decoy_port, fallback)

    http_listen = '    listen %d default_server;\n' % int(st['http_port'])
    tls_listen = '    listen %d ssl http2 default_server;\n' % int(st['tls_port'])
    if ipv6:
        http_listen += '    listen [::]:%d default_server;\n' % int(st['http_port'])
        tls_listen += '    listen [::]:%d ssl http2 default_server;\n' % int(st['tls_port'])

    return (
        '# generated by ffv2ray.py - do not edit, changes are overwritten\n'
        + user_line +
        'worker_processes auto;\n'
        'pid /run/ff-v2ray-nginx.pid;\n'
        'error_log /var/log/xray/nginx-error.log warn;\n'
        'worker_rlimit_nofile 65535;\n'
        'events { worker_connections 8192; }\n'
        'http {\n'
        '  access_log off;\n'
        '  server_tokens off;\n'
        '  map $http_upgrade $connection_upgrade { default upgrade; \'\' close; }\n'
        '  server {\n'
        + http_listen +
        '    server_name _;\n'
        + locations() + fallback +
        '  }\n'
        '  server {\n'
        + tls_listen +
        '    server_name _;\n'
        '    ssl_certificate %s;\n'
        '    ssl_certificate_key %s;\n'
        '    ssl_protocols TLSv1.2 TLSv1.3;\n'
        '    ssl_session_cache shared:ffv2ray:10m;\n'
        '    ssl_session_timeout 1d;\n'
        + locations() + grpc_locations() + fallback +
        '  }\n'
        '}\n') % (st['cert'], st['key'])


def apply_all(force=False):
    """Re-render config files; restart Xray / nginx only when their config changed."""
    st = load_settings()
    users = load_users()
    usage = load_usage()
    now = int(time.time())
    try:
        os.makedirs('/var/log/xray', exist_ok=True)
    except OSError:
        pass

    cfg_text = json.dumps(render_xray(st, users, usage, now), indent=2, sort_keys=True) + '\n'
    xray_changed = cfg_text != read_text(XRAY_CONF)
    if xray_changed:
        write_text(XRAY_CONF, cfg_text)

    ngx_text = render_nginx(st)
    nginx_changed = ngx_text != read_text(NGINX_CONF)
    if nginx_changed:
        write_text(NGINX_CONF, ngx_text, 0o644)

    if xray_changed or force:
        run(['systemctl', 'restart', XRAY_SERVICE])
    if nginx_changed:
        run(['systemctl', 'restart', NGINX_SERVICE])
    return xray_changed, nginx_changed


# ------------------------------------------------------------------ stats
def query_stats(st):
    """Read (and reset) the per-user counters of Xray. None when Xray is not reachable."""
    cmd = [st['xray_bin'], 'api', 'statsquery', '--server=127.0.0.1:%d' % int(st['api_port']),
           '-pattern', 'user>>>', '-reset']
    rc, out, _ = run(cmd, timeout=10)
    if rc != 0:
        return None
    try:
        data = json.loads(out.strip() or '{}')
    except ValueError:
        return None
    result = {}
    for item in (data.get('stat') or []):
        parts = str(item.get('name', '')).split('>>>')
        if len(parts) != 4 or parts[0] != 'user' or parts[2] != 'traffic':
            continue
        try:
            val = int(item.get('value', 0) or 0)
        except (TypeError, ValueError):
            continue
        d = result.setdefault(parts[1], {'up': 0, 'down': 0})
        if parts[3] == 'uplink':
            d['up'] += val
        elif parts[3] == 'downlink':
            d['down'] += val
    return result


def accumulate(usage, deltas, now, dt=0):
    today = today_str(now)
    ulist = usage['users']
    for u in ulist.values():
        if u.get('day') != today:
            u['daily'] = 0
            u['day'] = today
        if deltas is not None and dt > 0:
            u['rate_up'] = 0
            u['rate_down'] = 0
    for name, d in (deltas or {}).items():
        u = ulist.setdefault(name, new_usage(now))
        total = d['up'] + d['down']
        u['up'] += d['up']
        u['down'] += d['down']
        u['total'] += total
        u['daily'] += total
        if total > 0:
            u['last'] = now
        if dt > 0:
            u['rate_up'] = d['up'] / float(dt)
            u['rate_down'] = d['down'] / float(dt)
    usage['ts'] = now


def collect_now(st):
    """Fold the traffic counted since the last poll into usage.json."""
    users = load_users()
    usage = load_usage()
    deltas = query_stats(st)
    if deltas is not None:
        accumulate(usage, deltas, int(time.time()))
        save_usage(usage, users)
    return usage


# ------------------------------------------------------------------ account links / cards
def client_opts(st):
    """(address, sni, host, insecure) used in client configs. With nothing set it is the plain domain."""
    d = st['domain']
    addr = (st.get('cfg_address') or '').strip() or d
    sni = (st.get('cfg_sni') or '').strip() or addr
    host = (st.get('cfg_host') or '').strip() or d
    # a TLS name that is not the server's own domain cannot match the server certificate
    insecure = (sni != d)
    return addr, sni, host, insecure


def build_client_json(st, name, u, kind):
    """Full client config (socks inbound + proxy outbound) for apps that import a JSON config.
    kind: 'tls' (WS+TLS), 'none' (WS, no TLS) or 'grpc' (gRPC+TLS)."""
    d, sni, host, insecure = client_opts(st)
    tls, http = int(st['tls_port']), int(st['http_port'])
    p = PROTOS[u['proto']]
    ident = u['id']
    port = http if kind == 'none' else tls
    if u['proto'] == 'vless':
        settings = {'vnext': [{'address': d, 'port': port,
                               'users': [{'id': ident, 'level': 8, 'encryption': 'none'}]}]}
    elif u['proto'] == 'vmess':
        settings = {'vnext': [{'address': d, 'port': port,
                               'users': [{'id': ident, 'alterId': 0, 'security': 'auto', 'level': 8}]}]}
    else:
        settings = {'servers': [{'address': d, 'port': port, 'password': ident, 'level': 8}]}
    tls_settings = {'serverName': sni, 'fingerprint': 'chrome', 'show': False}
    if insecure:
        tls_settings['allowInsecure'] = True
    if kind == 'grpc':
        stream = {'network': 'grpc', 'security': 'tls',
                  'grpcSettings': {'serviceName': p['grpc'], 'multiMode': False},
                  'tlsSettings': tls_settings}
    elif kind == 'none':
        stream = {'network': 'ws', 'security': 'none',
                  'wsSettings': {'path': p['path'], 'headers': {'Host': host}}}
    else:
        stream = {'network': 'ws', 'security': 'tls',
                  'wsSettings': {'path': p['path'], 'headers': {'Host': host}},
                  'tlsSettings': tls_settings}
    mux = {'enabled': False, 'concurrency': 8, 'xudpConcurrency': 8, 'xudpProxyUDP443': ''}
    cfg = {
        'remarks': name,
        'log': {'loglevel': 'warning'},
        'inbounds': [{'tag': 'socks', 'port': 10808, 'protocol': 'socks',
                      'settings': {'auth': 'noauth', 'udp': True, 'userLevel': 8},
                      'sniffing': {'enabled': True, 'destOverride': ['http', 'tls', 'quic'], 'routeOnly': False}}],
        'outbounds': [
            {'tag': 'proxy', 'protocol': u['proto'], 'settings': settings, 'streamSettings': stream,
             'mux': {'enabled': False, 'concurrency': -1, 'xudpConcurrency': 8, 'xudpProxyUDP443': ''}},
            {'tag': 'direct', 'protocol': 'freedom', 'settings': {'domainStrategy': 'UseIP'}, 'mux': dict(mux)},
            {'tag': 'block', 'protocol': 'blackhole', 'settings': {'response': {'type': 'http'}}, 'mux': dict(mux)},
        ],
        'dns': {
            'servers': ['1.1.1.1'],
            'hosts': {
                'domain:googleapis.cn': 'googleapis.com',
                'dns.alidns.com': ['223.5.5.5', '223.6.6.6', '2400:3200::1', '2400:3200:baba::1'],
                'one.one.one.one': ['1.1.1.1', '1.0.0.1', '2606:4700:4700::1111', '2606:4700:4700::1001'],
                'dot.pub': ['1.12.12.12', '120.53.53.53'],
                'dns.google': ['8.8.8.8', '8.8.4.4', '2001:4860:4860::8888', '2001:4860:4860::8844'],
                'dns.quad9.net': ['9.9.9.9', '149.112.112.112', '2620:fe::fe', '2620:fe::9'],
                'common.dot.dns.yandex.net': ['77.88.8.8', '77.88.8.1', '2a02:6b8::feed:0ff', '2a02:6b8:0:1::feed:0ff'],
            },
            'queryStrategy': 'UseIPv4',
        },
        'routing': {'domainStrategy': 'AsIs', 'rules': [
            {'type': 'field', 'ip': ['1.1.1.1'], 'outboundTag': 'proxy', 'port': '53'},
            {'type': 'field', 'ip': ['223.5.5.5'], 'outboundTag': 'direct', 'port': '53'},
        ]},
    }
    return json.dumps(cfg, separators=(',', ':'), ensure_ascii=False)


def build_links(st, name, u):
    links = _build_share_links(st, name, u)
    for label, kind in (('Json TLS', 'tls'), ('Json none TLS', 'none'), ('Json GRPC', 'grpc')):
        links.append((label, build_client_json(st, name, u, kind)))
    return links


def _build_share_links(st, name, u):
    d, sni, host, insecure = client_opts(st)
    custom = (d != st['domain']) or (sni != st['domain']) or (host != st['domain'])
    tls, http = int(st['tls_port']), int(st['http_port'])
    p = PROTOS[u['proto']]
    tag = urllib.parse.quote(name, safe='')
    ident = u['id']
    extra_tls = ''
    extra_none = ''
    if custom:
        extra_tls = '&host=%s&sni=%s%s' % (host, sni, '&allowInsecure=1' if insecure else '')
        extra_none = '&host=%s' % host
    if u['proto'] == 'vless':
        return [
            ('Link TLS', 'vless://%s@%s:%d?path=%s&security=tls&encryption=none&type=ws%s#%s' % (ident, d, tls, p['path'], extra_tls, tag)),
            ('Link none TLS', 'vless://%s@%s:%d?path=%s&encryption=none&type=ws%s#%s' % (ident, d, http, p['path'], extra_none, tag)),
            ('Link GRPC', 'vless://%s@%s:%d?mode=gun&security=tls&encryption=none&type=grpc&serviceName=%s&sni=%s%s#%s' % (ident, d, tls, p['grpc'], sni, '&allowInsecure=1' if insecure else '', tag)),
        ]
    if u['proto'] == 'vmess':
        def vm(port, net, path, tls_on, typ):
            obj = {'v': '2', 'ps': name, 'add': d, 'port': str(port), 'id': ident, 'aid': '0',
                   'scy': 'auto', 'net': net, 'type': typ, 'host': host, 'path': path,
                   'tls': 'tls' if tls_on else '', 'sni': sni if tls_on else ''}
            if tls_on and insecure:
                obj['allowInsecure'] = True
            raw = json.dumps(obj, separators=(',', ':')).encode()
            return 'vmess://' + base64.b64encode(raw).decode()
        return [
            ('Link TLS', vm(tls, 'ws', p['path'], True, 'none')),
            ('Link none TLS', vm(http, 'ws', p['path'], False, 'none')),
            ('Link GRPC', vm(tls, 'grpc', p['grpc'], True, 'gun')),
        ]
    path = urllib.parse.quote(p['path'], safe='')
    ins = '&allowInsecure=1' if insecure else ''
    return [
        ('Link TLS', 'trojan://%s@%s:%d?path=%s&security=tls&host=%s&type=ws&sni=%s%s#%s' % (ident, d, tls, path, host, sni, ins, tag)),
        ('Link none TLS', 'trojan://%s@%s:%d?path=%s&security=none&host=%s&type=ws#%s' % (ident, d, http, path, host, tag)),
        ('Link GRPC', 'trojan://%s@%s:%d?mode=gun&security=tls&type=grpc&serviceName=%s&sni=%s%s#%s' % (ident, d, tls, p['grpc'], sni, ins, tag)),
    ]


def row(key, val):
    return '%s : %s' % (key.ljust(14), val)


def limit_text(u):
    tl, dl = float(u.get('total_gb', 0)), float(u.get('daily_gb', 0))
    if tl <= 0 and dl <= 0:
        return 'Unlimited'
    parts = []
    if tl > 0:
        parts.append('%s GB total' % gb_str(tl))
    if dl > 0:
        parts.append('%s GB/day' % gb_str(dl))
    return ' | '.join(parts)


def account_card(name, u, st):
    p = PROTOS[u['proto']]
    bar = org('━' * 46)
    out = ['', bar, wht('  Xray/%s Account' % p['label']), bar]
    out.append(row('Remarks', name))
    out.append(row('Domain', st['domain']))
    out.append(row('port TLS', st['tls_port']))
    out.append(row('port none TLS', st['http_port']))
    out.append(row('Port  GRPC', st['tls_port']))
    if u['proto'] == 'trojan':
        out.append(row('Password', u['id']))
    else:
        out.append(row('id', u['id']))
    if u['proto'] == 'vless':
        out.append(row('Encryption', 'none'))
    elif u['proto'] == 'vmess':
        out.append(row('alterId', '0'))
        out.append(row('Security', 'auto'))
    out.append(row('Network', 'ws'))
    out.append(row('Path', p['path']))
    out.append(row('ServiceName', p['grpc']))
    out.append(bar)
    for label, link in build_links(st, name, u):
        out.append(row(label, cyn(link)))
        out.append(bar)
    out.append(row('Expired On', fmt_time(u['expiry']) if u.get('expiry') else 'Never'))
    out.append(row('Bandwidth', limit_text(u)))
    cl = user_conn_limit(u)
    out.append(row('Devices', str(cl) if cl > 0 else 'Unlimited'))
    out.append(bar)
    return '\n'.join(out)


def progress_bar(pct, width=30):
    pct = max(0.0, min(100.0, pct))
    filled = int(round(pct / 100.0 * width))
    color = grn if pct <= 50 else (yel if pct <= 80 else red)
    return color('[' + '█' * filled + '░' * (width - filled) + ']') + ' %.1f%%' % pct


def usage_card(name, u, usg, now):
    status = user_status(u, usg, now)
    tl, dl = quota_bytes(u.get('total_gb', 0)), quota_bytes(u.get('daily_gb', 0))
    out = ['', wht('--- Bandwidth Details: %s (%s) ---' % (name, u['proto'])), '']
    out.append(row('Status', status_label(status)))
    out.append(row('Data Used', '%s' % human(usg.get('total', 0))))
    if tl > 0:
        out.append(row('Total Limit', '%s GB' % gb_str(u['total_gb'])))
        out.append(row('Remaining', human(max(0, tl - usg.get('total', 0)))))
        out.append(row('Usage', progress_bar(usg.get('total', 0) * 100.0 / tl)))
    else:
        out.append(row('Total Limit', grn('Unlimited')))
    out.append(row('Used Today', human(usg.get('daily', 0))))
    if dl > 0:
        out.append(row('Daily Limit', '%s GB/day' % gb_str(u['daily_gb'])))
        out.append(row('Today', progress_bar(usg.get('daily', 0) * 100.0 / dl)))
    else:
        out.append(row('Daily Limit', grn('Unlimited')))
    out.append(row('Upload', human(usg.get('up', 0))))
    out.append(row('Download', human(usg.get('down', 0))))
    out.append(row('Speed now', 'down %s | up %s' % (human_rate(usg.get('rate_down', 0)), human_rate(usg.get('rate_up', 0)))))
    out.append(row('Expires', fmt_time(u['expiry']) if u.get('expiry') else 'Never'))
    if status == 'quota':
        out.append('\n' + red('  Total bandwidth finished - account is switched off'))
    elif status == 'daily':
        out.append('\n' + red('  Daily bandwidth finished - back after midnight'))
    return '\n'.join(out)


# ------------------------------------------------------------------ commands
def need_installed():
    st = load_settings()
    if not st.get('domain'):
        die('V2Ray is not set up yet (no settings found). Install it from the menu first.')
    return st


def cmd_api(a):
    print('FFV2RAY-API %d' % FFV2RAY_API)


def cmd_init(a):
    with locked():
        os.makedirs(V2_DIR, mode=0o700, exist_ok=True)
        st = load_settings()
        for key, attr in (('domain', 'domain'), ('tls_port', 'tls_port'), ('http_port', 'http_port'),
                          ('cert', 'cert'), ('key', 'key'), ('xray_bin', 'xray_bin'),
                          ('nginx_bin', 'nginx_bin'), ('decoy_port', 'decoy_port')):
            val = getattr(a, attr)
            if val is not None:
                st[key] = int(val) if key.endswith('_port') else val
        if st['tls_port'] == st['http_port']:
            die('TLS port and non-TLS port must be different.')
        write_json(SETTINGS_FILE, st)
        if not os.path.exists(USERS_FILE):
            save_users({})
        if not os.path.exists(USAGE_FILE):
            save_usage(load_usage())
        apply_all(force=False)
    print('OK')


def cmd_render(a):
    with locked():
        xc, nc = apply_all(force=a.restart)
    print('xray_changed=%s nginx_changed=%s' % (xc, nc))


def cmd_get(a):
    st = load_settings()
    print(st.get(a.key, ''))


def cmd_clientopts(a):
    """Show / set the client config options: connect address (bug host), SNI and WS Host header."""
    with locked():
        st = load_settings()
        changed = False
        if a.reset:
            for k in ('cfg_address', 'cfg_sni', 'cfg_host'):
                st[k] = ''
            changed = True
        for key, val in (('cfg_address', a.address), ('cfg_sni', a.sni), ('cfg_host', a.host)):
            if val is None:
                continue
            val = val.strip()
            if val and not HOST_RE.match(val):
                die('Invalid value for %s: use a domain name or IP (letters, digits, dot, dash).' % key[4:])
            st[key] = val
            changed = True
        if changed:
            write_json(SETTINGS_FILE, st)
    print(json.dumps({'address': st.get('cfg_address', ''), 'sni': st.get('cfg_sni', ''),
                      'host': st.get('cfg_host', ''), 'domain': st.get('domain', '')}))


def cmd_add(a):
    st = need_installed()
    name = a.name
    if a.proto not in PROTOS:
        die('Unknown protocol.')
    if not NAME_RE.match(name):
        die('Name must be 2-24 characters: letters, digits, _ or -')
    secs = int(a.days * 86400 + a.hours * 3600 + a.minutes * 60)
    if secs <= 0:
        die('Duration must be greater than zero.')
    custom_id = (a.id or '').strip()
    if custom_id and not ID_RE.match(custom_id):
        die('ID must be 3-30 characters: letters, digits, dot, _ or -')
    with locked():
        users = load_users()
        if name in users:
            die("Account '%s' already exists." % name)
        if custom_id and any(x.get('id') == custom_id for x in users.values()):
            die("ID '%s' is already used by another account." % custom_id)
        collect_now(st)
        now = int(time.time())
        users = load_users()
        users[name] = {
            'proto': a.proto, 'id': custom_id or str(uuid.uuid4()), 'created': now, 'expiry': now + secs,
            'total_gb': a.total, 'daily_gb': a.daily, 'locked': False, 'trial': bool(a.trial),
            'conn_limit': max(0, int(a.conn)), 'owner': a.owner or 'admin',
        }
        save_users(users)
        usage = load_usage()
        usage['users'][name] = new_usage(now)
        save_usage(usage, users)
        apply_all()
    print('OK')


def cmd_exists(a):
    sys.exit(0 if a.name in load_users() else 1)


def _need_user(users, name):
    if name not in users:
        die("Account '%s' was not found." % name)
    return users[name]


def cmd_del(a):
    st = need_installed()
    with locked():
        users = load_users()
        _need_user(users, a.name)
        collect_now(st)
        users = load_users()
        del users[a.name]
        save_users(users)
        usage = load_usage()
        save_usage(usage, users)
        apply_all()
    print('OK')


def cmd_renew(a):
    st = need_installed()
    with locked():
        users = load_users()
        u = _need_user(users, a.name)
        collect_now(st)
        users = load_users()
        u = users[a.name]
        now = int(time.time())
        base = max(now, u.get('expiry') or 0)
        u['expiry'] = base + int(a.days * 86400)
        save_users(users)
        if a.reset:
            usage = load_usage()
            usage['users'][a.name] = new_usage(now)
            save_usage(usage, users)
        apply_all()
    print('OK')


def cmd_limit(a):
    st = need_installed()
    with locked():
        users = load_users()
        _need_user(users, a.name)
        collect_now(st)
        users = load_users()
        if a.total is not None:
            users[a.name]['total_gb'] = a.total
        if a.daily is not None:
            users[a.name]['daily_gb'] = a.daily
        if a.conn is not None:
            users[a.name]['conn_limit'] = max(0, int(a.conn))
            lim = load_limits()                      # new limit: forget old blocks of this account
            if lim['blocks'].pop(a.name, None) is not None:
                save_limits(lim)
        save_users(users)
        if a.reset:
            usage = load_usage()
            usage['users'][a.name] = new_usage(int(time.time()))
            save_usage(usage, users)
        apply_all()
    print('OK')


def _set_lock(name, value):
    st = need_installed()
    with locked():
        users = load_users()
        _need_user(users, name)
        collect_now(st)
        users = load_users()
        users[name]['locked'] = value
        save_users(users)
        apply_all()
    print('OK')


def cmd_lock(a):
    _set_lock(a.name, True)


def cmd_unlock(a):
    _set_lock(a.name, False)


def cmd_cleanup(a):
    st = need_installed()
    with locked():
        collect_now(st)
        users = load_users()
        usage = load_usage()
        now = int(time.time())
        gone = [n for n, u in users.items()
                if u.get('expiry') and now >= u['expiry']]
        for n in gone:
            del users[n]
        save_users(users)
        save_usage(usage, users)
        apply_all()
    print('Removed %d expired account(s).' % len(gone))


def select_names(proto=None):
    users = load_users()
    names = sorted(users)
    if proto:
        names = [n for n in names if users[n]['proto'] == proto]
    return users, names


def cmd_names(a):
    users, names = select_names(a.proto)
    usage = load_usage()
    now = int(time.time())
    for n in names:
        u = users[n]
        usg = usage['users'].get(n, {})
        print('%s|%s|%s|%s|%s' % (n, u['proto'], user_status(u, usg, now),
                                  fmt_time(u['expiry']) if u.get('expiry') else 'Never',
                                  usage_text(u, usg)))


def cmd_counts(a):
    users = load_users()
    counts = {p: 0 for p in PROTO_ORDER}
    for u in users.values():
        counts[u['proto']] = counts.get(u['proto'], 0) + 1
    print(' '.join('%s=%d' % (p, counts[p]) for p in PROTO_ORDER))


def mag(s): return C.c('0;35', s)


SPINNER = '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
SPEED_FLOOR = 1048576.0       # the speed bars are at least 1 MB/s wide, so tiny speeds do not look full


def term_size():
    try:
        sz = shutil.get_terminal_size((80, 24))
        return sz.columns, sz.lines
    except Exception:
        return 80, 24


def bar(frac, width, color):
    frac = max(0.0, min(1.0, frac))
    filled = int(round(frac * width))
    return color('█' * filled) + dim('░' * (width - filled))


def pct_color(frac):
    return grn if frac <= 0.5 else (yel if frac <= 0.8 else red)


def stat_row(label, frac, width, color, text):
    return '  %s %s %s' % (label.ljust(8), bar(frac, width, color), text)


def collect_view(proto):
    """Everything the dashboard needs, read once (the live view calls this about once a second)."""
    users, names = select_names(proto)
    usage = load_usage()
    now = int(time.time())
    devs = device_activity()
    return {'users': users, 'names': names, 'usage': usage, 'now': now, 'devs': devs}


def dashboard(view, disp, frame, cols, animate):
    """One block of lines per account: devices, today, total, download and upload speed as bars.
    `disp` keeps the speeds that are drawn so the speed bars glide to their new value."""
    users, names, usage, now, devs = view['users'], view['names'], view['usage'], view['now'], view['devs']
    today = today_str(now)
    fresh = (now - usage.get('ts', 0)) <= 20          # the limiter service must be updating the counters
    width = max(8, min(24, cols - 40))

    info = {}
    for n in names:
        usg = usage['users'].get(n, {})
        daily = usg.get('daily', 0) if usg.get('day') == today else 0
        r_dn = usg.get('rate_down', 0) if fresh else 0
        r_up = usg.get('rate_up', 0) if fresh else 0
        d = disp.setdefault(n, {'down': 0.0, 'up': 0.0})
        for key, target in (('down', r_dn), ('up', r_up)):
            if animate:
                d[key] += (target - d[key]) * 0.35
                if abs(target - d[key]) < 1:
                    d[key] = float(target)
            else:
                d[key] = float(target)
        info[n] = (usg, daily, d['down'], d['up'])

    max_daily = max([v[1] for v in info.values()] + [1])
    max_total = max([v[0].get('total', 0) for v in info.values()] + [1])
    scale = max([SPEED_FLOOR] + [v[2] for v in info.values()] + [v[3] for v in info.values()])
    live_n = 0
    blocks = []
    for n in names:
        u = users[n]
        usg, daily, r_dn, r_up = info[n]
        status = user_status(u, usg, now)
        live = bool(usg.get('last', 0) and now - usg['last'] <= 30 and fresh)
        live_n += 1 if live else 0
        if live:
            dot = grn(SPINNER[frame % len(SPINNER)] if animate else '●')
        else:
            dot = dim('○')
        head = '%s %s %s %s' % (dot, wht(n[:14].ljust(14)), dim(('[%s]' % u['proto']).ljust(8)), status_label(status))
        if u.get('expiry'):
            head += dim('  exp ' + fmt_time(u['expiry']).split(' ')[0])
        rows = [head]

        # connection limit / devices online
        cl = user_conn_limit(u)
        dv = device_count(devs.get(n))
        if cl > 0:
            frac = dv / float(cl)
            rows.append(stat_row('Devices', frac, width, pct_color(frac), '%d / %d online' % (dv, cl)))
        else:
            rows.append(stat_row('Devices', min(1.0, dv / 5.0), width, cyn, '%d online (no limit)' % dv))

        # today and total usage
        dl, tl = quota_bytes(u.get('daily_gb', 0)), quota_bytes(u.get('total_gb', 0))
        if dl > 0:
            frac = daily / float(dl)
            rows.append(stat_row('Today', frac, width, pct_color(frac),
                                 '%s / %s GB  %d%%' % (human(daily), gb_str(u['daily_gb']), int(frac * 100))))
        else:
            rows.append(stat_row('Today', daily / float(max_daily), width, cyn, '%s (no limit)' % human(daily)))
        total = usg.get('total', 0)
        if tl > 0:
            frac = total / float(tl)
            rows.append(stat_row('Total', frac, width, pct_color(frac),
                                 '%s / %s GB  %d%%' % (human(total), gb_str(u['total_gb']), int(frac * 100))))
        else:
            rows.append(stat_row('Total', total / float(max_total), width, cyn, '%s (no limit)' % human(total)))

        # speed now (bars share one scale, so accounts can be compared) + what was moved in total
        rows.append(stat_row('↓ Down', r_dn / scale, width, cyn,
                             '%s  %s' % (human_rate(r_dn).ljust(11), dim('total ' + human(usg.get('down', 0))))))
        rows.append(stat_row('↑ Up', r_up / scale, width, mag,
                             '%s  %s' % (human_rate(r_up).ljust(11), dim('total ' + human(usg.get('up', 0))))))
        blocks.append(rows)

    tot_dn = sum(v[2] for v in info.values())
    tot_up = sum(v[3] for v in info.values())
    summary = '%d account%s · %d live · ↓ %s  ↑ %s' % (len(names), '' if len(names) == 1 else 's', live_n,
                                                     human_rate(tot_dn), human_rate(tot_up))
    warn = None if fresh else red('! limiter service has not updated the counters - speeds show 0')
    return blocks, summary, warn


def render_static(view, proto):
    disp = {}
    cols = term_size()[0]
    blocks, summary, warn = dashboard(view, disp, 0, cols, False)
    out = [wht('V2RAY USERS') + '  ' + dim(summary), dim('─' * min(cols - 1, 60))]
    if warn:
        out.append(warn)
    for rows in blocks:
        out.extend(rows)
        out.append('')
    return out


def cmd_list(a):
    users, names = select_names(a.proto)
    if not names:
        print(yel('No accounts found.'))
        return
    interactive = sys.stdout.isatty() and sys.stdin.isatty() and not a.once
    if not interactive:
        print('\n'.join(render_static(collect_view(a.proto), a.proto)))
        return
    try:
        import select
        import termios
        import tty
    except ImportError:                                # no terminal control: fall back to one static view
        print('\n'.join(render_static(collect_view(a.proto), a.proto)))
        return
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    disp, page, frame, next_load, view = {}, 0, 0, 0.0, None
    sys.stdout.write('\033[?25l\033[2J')
    try:
        tty.setcbreak(fd)
        while True:
            t = time.time()
            if view is None or t >= next_load:
                view = collect_view(a.proto)
                next_load = t + 1.0
            cols, rows_avail = term_size()
            blocks, summary, warn = dashboard(view, disp, frame, cols, True)
            per_page = max(1, (rows_avail - 6) // 7)       # a block is 6 lines + 1 blank line
            pages = max(1, (len(blocks) + per_page - 1) // per_page)
            page = max(0, min(page, pages - 1))
            out = [wht('V2RAY USERS') + '  ' + dim(summary), dim('─' * min(cols - 1, 60))]
            if warn:
                out.append(warn)
            for rows in blocks[page * per_page:(page + 1) * per_page]:
                out.extend(rows)
                out.append('')
            keys = '[n]ext [p]rev ' if pages > 1 else ''
            out.append(dim('page %d/%d   %s[q] quit   live, refreshes every second' % (page + 1, pages, keys)))
            sys.stdout.write('\033[H' + '\033[K\n'.join(out) + '\033[K\n\033[J')
            sys.stdout.flush()
            frame += 1
            if select.select([fd], [], [], 0.2)[0]:
                key = os.read(fd, 8)
                if key in (b'q', b'Q'):
                    break
                if key in (b'n', b'N', b' ', b'\x1b[C', b'\x1b[B'):
                    page = (page + 1) % pages
                elif key in (b'p', b'P', b'\x1b[D', b'\x1b[A'):
                    page = (page - 1) % pages
                sys.stdout.write('\033[2J')
    except KeyboardInterrupt:
        pass
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
        sys.stdout.write('\033[?25h\n')
        sys.stdout.flush()


def cmd_show(a):
    st = need_installed()
    users = load_users()
    u = _need_user(users, a.name)
    print(account_card(a.name, u, st))


def cmd_usage(a):
    users = load_users()
    u = _need_user(users, a.name)
    usage = load_usage()
    print(usage_card(a.name, u, usage['users'].get(a.name, new_usage(int(time.time()))), int(time.time())))


LOG_RE = re.compile(r'^(\d{4}/\d\d/\d\d \d\d:\d\d:\d\d)(?:\.\d+)? (?:from )?(\S+) accepted .*?email: (\S+)')


def recent_log_activity(window):
    """{email: {'ips': set, 'conns': n, 'last': ts}} from the Xray access log."""
    result = {}
    try:
        size = os.path.getsize(ACCESS_LOG)
        with open(ACCESS_LOG, 'rb') as f:
            f.seek(max(0, size - 4 * 1024 * 1024))
            data = f.read().decode('utf-8', 'replace')
    except (IOError, OSError):
        return result
    now = time.time()
    for line in data.splitlines():
        m = LOG_RE.match(line)
        if not m:
            continue
        try:
            ts = time.mktime(time.strptime(m.group(1), '%Y/%m/%d %H:%M:%S'))
        except ValueError:
            continue
        if now - ts > window:
            continue
        addr = m.group(2)
        ip = addr.rsplit(':', 1)[0].strip('[]') if ':' in addr else addr
        d = result.setdefault(m.group(3), {'ips': set(), 'conns': 0, 'last': 0})
        d['ips'].add(ip)
        d['conns'] += 1
        d['last'] = max(d['last'], ts)
    return result


def _log_ip(addr):
    """Client IP out of the address field of an Xray access-log line."""
    for pre in ('tcp:', 'udp:'):
        if addr.startswith(pre):
            addr = addr[len(pre):]
    if addr.startswith('['):
        return addr[1:addr.find(']')] if ']' in addr else addr.strip('[]')
    return addr.rsplit(':', 1)[0] if ':' in addr else addr


_dev_cache = {'t': 0.0, 'w': 0, 'v': {}}


def device_activity(window=DEVICE_WINDOW):
    """{email: {'ips': {ip: first_ts}, 'last_ip': {ip: ts}, 'conns': n, 'last': ts, 'proxy': bool}}
    Devices are told apart by their source IP. Connections that Xray sees as local (127.0.0.1)
    cannot be told apart, they only show that the account is active. A device that was refused
    because the account is over its limit is not counted while it is refused."""
    nowt = time.time()
    if _dev_cache['v'] and _dev_cache['w'] == window and nowt - _dev_cache['t'] < 2:
        return _dev_cache['v']
    blocks = load_limits().get('blocks', {})
    result = {}
    try:
        size = os.path.getsize(ACCESS_LOG)
        with open(ACCESS_LOG, 'rb') as f:
            f.seek(max(0, size - 4 * 1024 * 1024))
            data = f.read().decode('utf-8', 'replace')
    except (IOError, OSError):
        return result
    for line in data.splitlines():
        m = LOG_RE.match(line)
        if not m:
            continue
        try:
            ts = time.mktime(time.strptime(m.group(1), '%Y/%m/%d %H:%M:%S'))
        except ValueError:
            continue
        if nowt - ts > window:
            continue
        ip, name = _log_ip(m.group(2)), m.group(3)
        d = result.setdefault(name, {'ips': {}, 'last_ip': {}, 'conns': 0, 'last': 0, 'proxy': False})
        if ip in LOCAL_IPS:
            d['proxy'] = True
        else:
            if ts < blocks.get(name, {}).get(ip, 0):
                continue                              # refused device: ignore its attempts
            d['ips'].setdefault(ip, ts)
            d['last_ip'][ip] = max(d['last_ip'].get(ip, 0), ts)
        d['conns'] += 1
        d['last'] = max(d['last'], ts)
    _dev_cache.update(t=nowt, w=window, v=result)
    return result


def device_count(d):
    """Number of devices online for one account entry of device_activity()."""
    if not d:
        return 0
    return max(len(d['ips']), 1 if d['conns'] else 0)


def cmd_online(a):
    users, names = select_names(a.proto)
    if a.name:
        _need_user(users, a.name)
        names = [a.name]
    if not names:
        print(yel('No accounts found.'))
        return
    window = a.minutes * 60
    log = recent_log_activity(window)
    usage = load_usage()
    now = time.time()
    print(wht('Login check (live = traffic in last 30s, recent = connections in last %d min)' % a.minutes))
    print(dim('-' * 66))
    for n in names:
        usg = usage['users'].get(n, {})
        live = usg.get('last', 0) and now - usg['last'] <= 30
        d = log.get(n)
        dot = grn('●') if live else (yel('●') if d else dim('○'))
        state = grn('LIVE') if live else (yel('recent') if d else dim('offline'))
        extra = ''
        if d:
            ips = sorted(i for i in d['ips'] if i not in ('127.0.0.1', '::1'))
            extra = '  conns:%d  ips:%s  last:%ds ago' % (
                d['conns'], (','.join(ips[:3]) if ips else 'via proxy'), int(now - d['last']))
        cl = user_conn_limit(users[n])
        dv = device_count(device_activity().get(n))
        extra += '  devices:%d/%s' % (dv, cl if cl > 0 else 'inf')
        print('%s %-14s %-6s %s%s' % (dot, n[:14], users[n]['proto'], state, extra))


def build_monitor():
    st = load_settings()
    users = load_users()
    usage = load_usage()
    now = int(time.time())
    lines = [wht('XRAY LIVE BANDWIDTH MONITOR') + dim('   (Ctrl+C to exit)'), dim('─' * 50)]
    age = now - usage.get('ts', 0)
    if age > 20:
        lines.append(red('! limiter service has not updated for %ds - is it running?' % age))
    if not users:
        lines.append(yel('No accounts yet.'))
    tot_rate_d = tot_rate_u = 0
    for n in sorted(users):
        u = users[n]
        usg = usage['users'].get(n, new_usage(now))
        status = user_status(u, usg, now)
        tl = quota_bytes(u.get('total_gb', 0))
        dl = quota_bytes(u.get('daily_gb', 0))
        live = usg.get('last', 0) and now - usg['last'] <= 30
        lines.append('%s %s %s  %s' % (grn('●') if live else dim('○'), wht(n), dim('[%s]' % u['proto']), status_label(status)))
        if tl > 0:
            lines.append('   Total : %s / %s GB  %s' % (human(usg.get('total', 0)), gb_str(u['total_gb']),
                                                         progress_bar(usg.get('total', 0) * 100.0 / tl, 16)))
        else:
            lines.append('   Total : %s / Unlimited' % human(usg.get('total', 0)))
        if dl > 0:
            lines.append('   Today : %s / %s GB  %s' % (human(usg.get('daily', 0)), gb_str(u['daily_gb']),
                                                         progress_bar(usg.get('daily', 0) * 100.0 / dl, 16)))
        else:
            lines.append('   Today : %s' % human(usg.get('daily', 0)))
        lines.append('   Speed : down %s | up %s' % (human_rate(usg.get('rate_down', 0)), human_rate(usg.get('rate_up', 0))))
        lines.append('   Exp   : %s' % (fmt_time(u['expiry']) if u.get('expiry') else 'Never'))
        tot_rate_d += usg.get('rate_down', 0)
        tot_rate_u += usg.get('rate_up', 0)
    lines.append(dim('─' * 50))
    lines.append('All users now: down %s | up %s' % (human_rate(tot_rate_d), human_rate(tot_rate_u)))
    return '\n'.join(lines)


def cmd_monitor(a):
    if a.once:
        print(build_monitor())
        return
    try:
        while True:
            sys.stdout.write('\033[H\033[2J' + build_monitor() + '\n')
            sys.stdout.flush()
            time.sleep(1)
    except KeyboardInterrupt:
        print()


def enforce_device_limits(users, now):
    """Per account: keep the oldest `conn_limit` devices, refuse the newer ones for BLOCK_SECONDS."""
    lim = load_limits()
    blocks, old_devs = lim['blocks'], lim['devices']
    for name in list(blocks):                         # forget finished / orphaned blocks
        if name not in users or user_conn_limit(users[name]) <= 0:
            del blocks[name]
            continue
        for ip in list(blocks[name]):
            if blocks[name][ip] + DEVICE_WINDOW < now:
                del blocks[name][ip]
        if not blocks[name]:
            del blocks[name]
    devs = {}
    for name, d in device_activity(DEVICE_WINDOW).items():
        if name not in users:
            continue
        cur = {}
        for ip, first in d['ips'].items():
            cur[ip] = {'since': old_devs.get(name, {}).get(ip, {}).get('since', first),
                       'last': d['last_ip'].get(ip, first)}
        limit = user_conn_limit(users[name])
        if limit > 0 and len(cur) > limit:
            order = sorted(cur, key=lambda i: (cur[i]['since'], i))
            for ip in order[limit:]:
                if blocks.get(name, {}).get(ip, 0) <= now:
                    blocks.setdefault(name, {})[ip] = now + BLOCK_SECONDS
                del cur[ip]
        devs[name] = cur
    lim['devices'] = devs
    save_limits(lim)


def daemon_tick(last_ts):
    """One poll: count traffic, enforce limits, drop expired trials, re-render when needed."""
    st = load_settings()
    if not st.get('domain'):
        return last_ts
    with locked():
        users = load_users()
        usage = load_usage()
        now = int(time.time())
        dt = (now - last_ts) if last_ts else 0
        deltas = query_stats(st)
        if deltas is not None:
            accumulate(usage, deltas, now, dt if dt > 0 else 1)
        else:
            usage['ts'] = now
        trial_gone = [n for n, u in users.items()
                      if u.get('trial') and u.get('expiry') and now >= u['expiry']]
        if trial_gone:
            for n in trial_gone:
                del users[n]
            save_users(users)
        save_usage(usage, users)
        try:
            enforce_device_limits(users, now)
        except Exception as exc:                   # a log problem must never stop the bandwidth limiter
            sys.stderr.write('ffv2ray device limit error: %s\n' % exc)
        apply_all()
    return now


def cmd_daemon(a):
    last = 0
    while True:
        try:
            last = daemon_tick(last)
        except Exception as exc:                   # never let the limiter die
            sys.stderr.write('ffv2ray daemon error: %s\n' % exc)
        if a.once:
            return
        time.sleep(INTERVAL)


# ------------------------------------------------------------------ argument parsing
def num(s):
    try:
        v = float(s)
    except ValueError:
        raise argparse.ArgumentTypeError('not a number: %s' % s)
    if v < 0:
        raise argparse.ArgumentTypeError('must not be negative')
    return v


def build_parser():
    p = argparse.ArgumentParser(prog='ffv2ray')
    sub = p.add_subparsers(dest='cmd')
    sub.required = True

    sub.add_parser('api').set_defaults(fn=cmd_api)

    s = sub.add_parser('init')
    for opt in ('domain', 'tls-port', 'http-port', 'cert', 'key', 'xray-bin', 'nginx-bin', 'decoy-port'):
        s.add_argument('--' + opt, dest=opt.replace('-', '_'), default=None)
    s.set_defaults(fn=cmd_init)

    s = sub.add_parser('render')
    s.add_argument('--restart', action='store_true')
    s.set_defaults(fn=cmd_render)

    s = sub.add_parser('get')
    s.add_argument('key')
    s.set_defaults(fn=cmd_get)

    s = sub.add_parser('fakesite')
    s.add_argument('--template', default=None, help='business | cloud | blog')
    s.add_argument('--off', action='store_true', help='remove the fake website')
    s.set_defaults(fn=cmd_fakesite)

    s = sub.add_parser('clientopts')
    s.add_argument('--address', default=None, help='connect address / bug host (empty = use the domain)')
    s.add_argument('--sni', default=None, help='TLS server name (empty = same as the address)')
    s.add_argument('--host', default=None, help='WebSocket Host header (empty = the real domain)')
    s.add_argument('--reset', action='store_true')
    s.set_defaults(fn=cmd_clientopts)

    s = sub.add_parser('add')
    s.add_argument('--proto', required=True)
    s.add_argument('--name', required=True)
    s.add_argument('--days', type=num, default=0)
    s.add_argument('--hours', type=num, default=0)
    s.add_argument('--minutes', type=num, default=0)
    s.add_argument('--total', type=num, default=0)
    s.add_argument('--daily', type=num, default=0)
    s.add_argument('--trial', action='store_true')
    s.add_argument('--conn', type=int, default=0, help='max devices (0 = unlimited)')
    s.add_argument('--owner', default='admin')
    s.add_argument('--id', default='', help='custom short id / password (default: random UUID)')
    s.set_defaults(fn=cmd_add)

    s = sub.add_parser('exists')
    s.add_argument('name')
    s.set_defaults(fn=cmd_exists)

    for cname, fn in (('del', cmd_del), ('lock', cmd_lock), ('unlock', cmd_unlock),
                      ('show', cmd_show), ('usage', cmd_usage)):
        s = sub.add_parser(cname)
        s.add_argument('name')
        s.set_defaults(fn=fn)

    s = sub.add_parser('renew')
    s.add_argument('name')
    s.add_argument('--days', type=num, required=True)
    s.add_argument('--reset', action='store_true')
    s.set_defaults(fn=cmd_renew)

    s = sub.add_parser('limit')
    s.add_argument('name')
    s.add_argument('--total', type=num, default=None)
    s.add_argument('--daily', type=num, default=None)
    s.add_argument('--conn', type=int, default=None, help='max devices (0 = unlimited)')
    s.add_argument('--reset', action='store_true')
    s.set_defaults(fn=cmd_limit)

    sub.add_parser('cleanup').set_defaults(fn=cmd_cleanup)
    sub.add_parser('counts').set_defaults(fn=cmd_counts)

    s = sub.add_parser('names')
    s.add_argument('--proto', default=None)
    s.set_defaults(fn=cmd_names)

    s = sub.add_parser('list')
    s.add_argument('--proto', default=None)
    s.add_argument('--once', action='store_true', help='print once instead of the live view')
    s.set_defaults(fn=cmd_list)

    s = sub.add_parser('online')
    s.add_argument('name', nargs='?', default=None)
    s.add_argument('--proto', default=None)
    s.add_argument('--minutes', type=int, default=10)
    s.set_defaults(fn=cmd_online)

    s = sub.add_parser('monitor')
    s.add_argument('--once', action='store_true')
    s.set_defaults(fn=cmd_monitor)

    s = sub.add_parser('daemon')
    s.add_argument('--once', action='store_true')
    s.set_defaults(fn=cmd_daemon)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    try:
        args.fn(args)
    except BrokenPipeError:
        try:
            sys.stdout.close()
        except Exception:
            pass
        sys.exit(0)


if __name__ == '__main__':
    main()
