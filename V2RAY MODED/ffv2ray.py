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
FFV2RAY_API = 2

import argparse
import base64
import contextlib
import fcntl
import json
import os
import pwd
import re
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
}

NAME_RE = re.compile(r'^[A-Za-z0-9_-]{2,24}$')


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
        + locations() +
        '    location / { return 404; }\n'
        '  }\n'
        '  server {\n'
        + tls_listen +
        '    server_name _;\n'
        '    ssl_certificate %s;\n'
        '    ssl_certificate_key %s;\n'
        '    ssl_protocols TLSv1.2 TLSv1.3;\n'
        '    ssl_session_cache shared:ffv2ray:10m;\n'
        '    ssl_session_timeout 1d;\n'
        + locations() + grpc_locations() +
        '    location / { return 404; }\n'
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
def build_links(st, name, u):
    d = st['domain']
    tls, http = int(st['tls_port']), int(st['http_port'])
    p = PROTOS[u['proto']]
    tag = urllib.parse.quote(name, safe='')
    ident = u['id']
    if u['proto'] == 'vless':
        return [
            ('Link TLS', 'vless://%s@%s:%d?path=%s&security=tls&encryption=none&type=ws#%s' % (ident, d, tls, p['path'], tag)),
            ('Link none TLS', 'vless://%s@%s:%d?path=%s&encryption=none&type=ws#%s' % (ident, d, http, p['path'], tag)),
            ('Link GRPC', 'vless://%s@%s:%d?mode=gun&security=tls&encryption=none&type=grpc&serviceName=%s&sni=%s#%s' % (ident, d, tls, p['grpc'], d, tag)),
        ]
    if u['proto'] == 'vmess':
        def vm(port, net, path, tls_on, typ):
            obj = {'v': '2', 'ps': name, 'add': d, 'port': str(port), 'id': ident, 'aid': '0',
                   'scy': 'auto', 'net': net, 'type': typ, 'host': d, 'path': path,
                   'tls': 'tls' if tls_on else '', 'sni': d if tls_on else ''}
            raw = json.dumps(obj, separators=(',', ':')).encode()
            return 'vmess://' + base64.b64encode(raw).decode()
        return [
            ('Link TLS', vm(tls, 'ws', p['path'], True, 'none')),
            ('Link none TLS', vm(http, 'ws', p['path'], False, 'none')),
            ('Link GRPC', vm(tls, 'grpc', p['grpc'], True, 'gun')),
        ]
    path = urllib.parse.quote(p['path'], safe='')
    return [
        ('Link TLS', 'trojan://%s@%s:%d?path=%s&security=tls&host=%s&type=ws&sni=%s#%s' % (ident, d, tls, path, d, d, tag)),
        ('Link none TLS', 'trojan://%s@%s:%d?path=%s&security=none&host=%s&type=ws#%s' % (ident, d, http, path, d, tag)),
        ('Link GRPC', 'trojan://%s@%s:%d?mode=gun&security=tls&type=grpc&serviceName=%s&sni=%s#%s' % (ident, d, tls, p['grpc'], d, tag)),
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
                          ('nginx_bin', 'nginx_bin')):
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
    with locked():
        users = load_users()
        if name in users:
            die("Account '%s' already exists." % name)
        collect_now(st)
        now = int(time.time())
        users = load_users()
        users[name] = {
            'proto': a.proto, 'id': str(uuid.uuid4()), 'created': now, 'expiry': now + secs,
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


def cmd_list(a):
    users, names = select_names(a.proto)
    if not names:
        print(yel('No accounts found.'))
        return
    usage = load_usage()
    now = int(time.time())
    print(wht('%-14s %-6s %-11s %-18s %s' % ('NAME', 'TYPE', 'STATUS', 'USED/LIMIT', 'EXPIRES')))
    print(dim('-' * 66))
    for n in names:
        u = users[n]
        usg = usage['users'].get(n, {})
        status = user_status(u, usg, now)
        text = STATUS_TEXT[status][0]
        line = '%-14s %-6s %-11s %-18s %s' % (n[:14], u['proto'], text, usage_text(u, usg),
                                              fmt_time(u['expiry']).split(' ')[0] if u.get('expiry') else 'Never')
        color = {'active': grn, 'locked': yel}.get(status, red)
        print(color(line))


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
    for opt in ('domain', 'tls-port', 'http-port', 'cert', 'key', 'xray-bin', 'nginx-bin'):
        s.add_argument('--' + opt, dest=opt.replace('-', '_'), default=None)
    s.set_defaults(fn=cmd_init)

    s = sub.add_parser('render')
    s.add_argument('--restart', action='store_true')
    s.set_defaults(fn=cmd_render)

    s = sub.add_parser('get')
    s.add_argument('key')
    s.set_defaults(fn=cmd_get)

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

    for cname, fn in (('names', cmd_names), ('list', cmd_list)):
        s = sub.add_parser(cname)
        s.add_argument('--proto', default=None)
        s.set_defaults(fn=fn)

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
