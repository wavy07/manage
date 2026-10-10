#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
import secrets
import hashlib
import threading
import re
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from http import cookies
from urllib.parse import urlparse, parse_qs
from datetime import datetime, timedelta

# --- CONSTANTS ---
# Everything lives under ONE base directory. It must be the same as DB_DIR in menu.sh.
# (menu.sh passes it through the systemd unit: Environment=PANEL_DB_DIR=...)
DB_DIR = os.environ.get("PANEL_DB_DIR", "/etc/visibleTech").rstrip("/") or "/etc/visibleTech"
DB_FILE = DB_DIR + "/users.db"
RESELLERS_DB = DB_DIR + "/resellers.db"
BW_DIR = DB_DIR + "/bandwidth"
PANEL_CONF = DB_DIR + "/panel.conf"
PANEL_HTML_DIR = DB_DIR + "/panel"
PANEL_HTML = PANEL_HTML_DIR + "/index.html"
LOGO_PATH = PANEL_HTML_DIR + "/logo.png"
BANNERS_ENABLED = DB_DIR + "/banners_enabled"
BANNER_DIR = DB_DIR + "/banners"
SSHD_BANNER_CONF = "/etc/ssh/sshd_config.d/visibleTech.conf"
TRIAL_CLEANUP_SCRIPT = "/usr/local/bin/visibleTech-trial-cleanup.sh"
FF_USERS_GROUP = "ffusers"
DEFAULT_PANEL_NAME = "visibleTech"
DEFAULT_PANEL_LOGO = "\U0001F99C"   # parrot, same as index.html
try:
    PORT = int(os.environ.get("PANEL_PORT", "44380"))
except ValueError:
    PORT = 44380

# --- GLOBAL STATE ---
SESSION_FILE = DB_DIR + "/sessions.json"
sessions = {}  # token -> {"username": str, "role": "admin"|"reseller", "created_at": float}

def load_sessions():
    global sessions
    try:
        if os.path.exists(SESSION_FILE):
            with open(SESSION_FILE, "r") as f:
                sessions = json.load(f)
    except Exception:
        sessions = {}

def save_sessions():
    try:
        os.makedirs(os.path.dirname(SESSION_FILE), exist_ok=True)
        with open(SESSION_FILE, "w") as f:
            json.dump(sessions, f)
    except Exception:
        pass

load_sessions()
db_lock = threading.Lock()

PROTOCOLS = [
    {"name": "OpenSSH", "service": "sshd", "service_alt": "ssh", "check_file": None, "port": "22"},
    {"name": "BadVPN (UDPGW)", "service": "badvpn", "check_file": "/etc/systemd/system/badvpn.service", "port": "7300"},
    {"name": "UDP Custom", "service": "udp-custom", "check_file": "/etc/systemd/system/udp-custom.service", "port": "36712"},
    {"name": "WebSocket Proxy", "service": "visibleTech-ws", "check_file": "/etc/systemd/system/visibleTech-ws.service",
     "port": "80", "port_conf": ("websocket_config.conf", "WS_PORTS")},
    {"name": "Stunnel (SSL/TLS)", "service": "visibleTech-stunnel", "check_file": "/etc/systemd/system/visibleTech-stunnel.service",
     "port": "443", "port_conf": ("stunnel_info.conf", "ST_PORT")},
    {"name": "FastDns (DNSTT)", "service": "server-sldns", "check_file": "/etc/systemd/system/server-sldns.service", "port": "53"},
    {"name": "EDNS Proxy", "service": "edns-proxy", "check_file": "/etc/systemd/system/edns-proxy.service", "port": "53"},
    {"name": "ZiVPN", "service": "zivpn", "check_file": "/etc/systemd/system/zivpn.service", "port": "5667"},
    {"name": "V2Ray (Xray)", "service": "ff-xray", "check_file": "/etc/systemd/system/ff-xray.service", "port": "443/80"},
    {"name": "X-UI / 3X-UI", "service": "x-ui", "check_file": "/etc/systemd/system/x-ui.service", "port": "2053"},
]

def conf_value(filename, key):
    """Read KEY="value" from a menu.sh config file in DB_DIR (no shell, no sourcing)."""
    try:
        with open(DB_DIR + "/" + filename, "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith(key + "="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    except Exception:
        pass
    return ""

# --- UTILS ---
def run_cmd(cmd_args, ignore_errors=False):
    try:
        if isinstance(cmd_args, str):
            res = subprocess.run(cmd_args, shell=True, capture_output=True, text=True, timeout=10)
        else:
            res = subprocess.run(cmd_args, capture_output=True, text=True, timeout=10)
        if not ignore_errors and res.returncode != 0:
            print(f"Command error: {cmd_args} -> {res.stderr}", file=sys.stderr)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        print(f"Exception running command {cmd_args}: {e}", file=sys.stderr)
        return -1, "", str(e)

def force_delete_system_user(username):
    """Kill all processes and force-delete a Linux system user."""
    import time as _time
    # Kill all processes owned by this user
    run_cmd(["pkill", "-9", "-u", username], ignore_errors=True)
    run_cmd(["killall", "-u", username, "-9"], ignore_errors=True)
    _time.sleep(0.5)
    # Force delete with retry
    code, _, _ = run_cmd(["userdel", "-rf", username], ignore_errors=True)
    if code != 0:
        # Retry after killing harder
        run_cmd(["pkill", "-9", "-u", username], ignore_errors=True)
        _time.sleep(1)
        run_cmd(["userdel", "-rf", username], ignore_errors=True)

# --- USERS DB ---
def parse_db_line(line):
    parts = line.strip().split(":")
    if len(parts) < 5:
        return None
    user = {
        "username": parts[0],
        "password": parts[1],
        "expire_date": parts[2],
        "conn_limit": int(parts[3]) if parts[3].isdigit() else 1,
        "bandwidth_gb": float(parts[4]),
        "daily_bandwidth_gb": 0.0,
        "account_type": "",
        "owner": "admin"
    }
    if len(parts) > 5:
        try:
            user["daily_bandwidth_gb"] = float(parts[5])
        except ValueError:
            user["daily_bandwidth_gb"] = 0.0
    if len(parts) > 6:
        user["account_type"] = parts[6]
    if len(parts) > 7:
        user["owner"] = parts[7] if parts[7] else "admin"
    return user

def read_db():
    users = []
    if not os.path.exists(DB_FILE):
        return users
    with open(DB_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            u = parse_db_line(line)
            if u:
                users.append(u)
    return users

def _fmt_bw(v):
    """Format bandwidth: 0.0 -> '0', 3.5 -> '3.5', 10.0 -> '10'"""
    f = float(v)
    return str(int(f)) if f == int(f) else str(f)

def format_db_line(u):
    bw = _fmt_bw(u.get('bandwidth_gb', 0))
    dbw = _fmt_bw(u.get('daily_bandwidth_gb', 0))
    owner = u.get('owner', 'admin')
    return f"{u['username']}:{u['password']}:{u['expire_date']}:{u['conn_limit']}:{bw}:{dbw}:{u.get('account_type','web')}:{owner}\n"

# --- RESELLERS DB ---
# line: username:password:expire_date:max_users:enabled[:type[:protocols[:max_conn]]]
#   max_conn  = highest connection/device limit this reseller may give to ONE account (0 = no cap)
#   type      = ssh | v2ray      (old lines without a type are SSH resellers)
#   protocols = all | vmess,vless,trojan   (only used by V2Ray resellers)
RESELLER_TYPES = ("ssh", "v2ray")

def norm_protos(val):
    """['all'] or an ordered list of valid V2Ray protocols ([] = nothing valid given)."""
    if isinstance(val, str):
        val = val.replace(";", ",").split(",")
    items = []
    for x in (val or []):
        x = str(x).strip().lower()
        if x == "all":
            return ["all"]
        if x in V2_PROTOS and x not in items:
            items.append(x)
    if len(items) == len(V2_PROTOS):
        return ["all"]
    return [p for p in V2_PROTOS if p in items]

def parse_reseller_line(line):
    parts = line.strip().split(":")
    if len(parts) < 5:
        return None
    rtype = parts[5].strip().lower() if len(parts) > 5 else "ssh"
    if rtype not in RESELLER_TYPES:
        rtype = "ssh"
    if rtype == "v2ray":
        protos = norm_protos(parts[6]) if len(parts) > 6 else ["all"]
    else:
        protos = []
    return {
        "username": parts[0],
        "password": parts[1],
        "expire_date": parts[2],
        "max_users": int(parts[3]) if parts[3].isdigit() else 10,
        "enabled": parts[4] == "1",
        "rtype": rtype,
        "protos": protos,
        "max_conn": int(parts[7]) if len(parts) > 7 and parts[7].strip().isdigit() else 0
    }

def read_resellers():
    resellers = []
    if not os.path.exists(RESELLERS_DB):
        return resellers
    with open(RESELLERS_DB, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            r = parse_reseller_line(line)
            if r:
                resellers.append(r)
    return resellers

def format_reseller_line(r):
    enabled = "1" if r.get("enabled", True) else "0"
    rtype = r.get("rtype", "ssh")
    protos = ",".join(r.get("protos", [])) if rtype == "v2ray" else ""
    return f"{r['username']}:{r['password']}:{r['expire_date']}:{r['max_users']}:{enabled}:{rtype}:{protos}:{int(r.get('max_conn', 0) or 0)}\n"

def write_resellers(resellers):
    os.makedirs(os.path.dirname(RESELLERS_DB), exist_ok=True)
    with open(RESELLERS_DB, "w") as f:
        for r in resellers:
            f.write(format_reseller_line(r))

def reseller_protos(r):
    """V2Ray protocols this reseller may sell (empty for SSH resellers)."""
    if not r or r.get("rtype") != "v2ray":
        return []
    return list(V2_PROTOS) if "all" in r.get("protos", []) else list(r.get("protos", []))

def get_reseller(session):
    if session.get("role") != "reseller":
        return None
    return next((x for x in read_resellers() if x["username"] == session.get("username")), None)

def reseller_conn_error(r, conn):
    """Error text when `conn` is above the reseller's per-account connection cap, else None."""
    cap = int((r or {}).get("max_conn", 0) or 0)
    if cap <= 0:
        return None
    if conn < 1 or conn > cap:
        return "Your max connection limit per account is %d" % cap
    return None

def reseller_problem(r):
    """Error text when the reseller may not work right now, else None."""
    if not r["enabled"]:
        return "Account is disabled"
    try:
        if datetime.strptime(r["expire_date"], "%Y-%m-%d") < datetime.now():
            return "Account has expired"
    except ValueError:
        pass
    return None

def v2_users_safe():
    """All V2Ray accounts ({} when V2Ray is not installed or unreadable)."""
    try:
        if not v2_installed():
            return {}
        mod = v2_module()
        return mod.load_users() if mod else {}
    except Exception as e:
        print(f"V2Ray users read error: {e}", file=sys.stderr)
        return {}

def v2_owned_names(username, users=None):
    users = v2_users_safe() if users is None else users
    return [n for n, u in users.items() if u.get("owner", "admin") == username]

def v2_online_map():
    """{account: {ips, devices, conns, last}} for V2Ray accounts that are online right now."""
    out = {}
    try:
        if not v2_installed():
            return out
        mod = v2_module()
        act = mod.device_activity(mod.DEVICE_WINDOW)
        for n, d in act.items():
            cnt = mod.device_count(d)
            if cnt:
                out[n] = {"ips": len(d["ips"]), "devices": cnt, "conns": d["conns"], "last": int(d["last"])}
        now = time.time()
        for n, usg in mod.load_usage()["users"].items():
            last = usg.get("last", 0)
            if last and now - last <= 60 and n not in out:   # traffic on a long-lived connection
                out[n] = {"ips": 0, "devices": 1, "conns": 0, "last": int(last)}
    except Exception as e:
        print(f"V2Ray online read error: {e}", file=sys.stderr)
    return out

# --- ONLINE SESSIONS ---
def get_online_sessions(target_user=None):
    managed_users = set(u["username"] for u in read_db())
    if target_user and target_user not in managed_users:
        return 0
    
    user_pids = {}
    try:
        code, out, _ = run_cmd(["ps", "-C", "sshd,sshd-session", "-o", "pid=,user="], ignore_errors=True)
        if code == 0 and out:
            for line in out.strip().splitlines():
                parts = line.split()
                if len(parts) != 2:
                    continue
                pid, owner = parts
                if owner in ("root", "sshd", ""):
                    continue
                if owner not in managed_users:
                    continue
                if target_user and owner != target_user:
                    continue
                if owner not in user_pids:
                    user_pids[owner] = set()
                user_pids[owner].add(pid)
    except Exception as e:
        print(f"Error checking online sessions: {e}", file=sys.stderr)
        
    if target_user:
        return len(user_pids.get(target_user, set()))
    else:
        return sum(len(pids) for pids in user_pids.values())

def get_online_sessions_for_users(usernames):
    """Get online session counts for a set of usernames efficiently (single ps call)."""
    user_pids = {}
    try:
        code, out, _ = run_cmd(["ps", "-C", "sshd,sshd-session", "-o", "pid=,user="], ignore_errors=True)
        if code == 0 and out:
            for line in out.strip().splitlines():
                parts = line.split()
                if len(parts) != 2:
                    continue
                pid, owner = parts
                if owner in ("root", "sshd", ""):
                    continue
                if owner not in usernames:
                    continue
                if owner not in user_pids:
                    user_pids[owner] = set()
                user_pids[owner].add(pid)
    except Exception as e:
        print(f"Error checking online sessions: {e}", file=sys.stderr)
    return user_pids

def read_file_int(path, default=0):
    try:
        if os.path.exists(path):
            with open(path, "r") as f:
                return int(f.read().strip())
    except Exception:
        pass
    return default

def refresh_ssh_banner_config():
    """Refresh dynamic SSH banner sshd config when banners are enabled."""
    if not os.path.exists(BANNERS_ENABLED):
        return
    sshd_ff_config = SSHD_BANNER_CONF
    banner_dir = BANNER_DIR
    os.makedirs(banner_dir, exist_ok=True)
    
    lines = ["# visibleTech - Dynamic per-user SSH banners\n"]
    users = read_db()
    for u in users:
        un = u["username"]
        lines.append(f"Match User {un}\n")
        lines.append(f"    Banner {banner_dir}/{un}.txt\n")
    
    new_content = "".join(lines)
    
    # Only update if changed
    old_content = ""
    if os.path.exists(sshd_ff_config):
        try:
            with open(sshd_ff_config, "r") as f:
                old_content = f.read()
        except:
            pass
    
    if new_content != old_content:
        try:
            with open(sshd_ff_config, "w") as f:
                f.write(new_content)
            # Ensure Include directive exists
            try:
                with open("/etc/ssh/sshd_config", "r") as f:
                    sshd_content = f.read()
                if "Include /etc/ssh/sshd_config.d/" not in sshd_content:
                    with open("/etc/ssh/sshd_config", "a") as f:
                        f.write("\nInclude /etc/ssh/sshd_config.d/*.conf\n")
            except:
                pass
            run_cmd("systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null", ignore_errors=True)
        except Exception as e:
            print(f"Error refreshing SSH banner config: {e}", file=sys.stderr)

# --- PANEL CREDS ---
def get_panel_creds():
    creds = {"PANEL_USER": "", "PANEL_PASS_HASH": "", "PANEL_PASS_PLAIN": "", "PANEL_SECRET": "", "PANEL_NAME": DEFAULT_PANEL_NAME, "PANEL_LOGO": DEFAULT_PANEL_LOGO}
    if os.path.exists(PANEL_CONF):
        with open(PANEL_CONF, "r") as f:
            for line in f:
                line = line.strip()
                if "=" in line:
                    k, v = line.split("=", 1)
                    v = v.strip().strip('"').strip("'")
                    if k in creds:
                        creds[k] = v
    return creds

def write_panel_creds(user, pass_plain, secret=None, panel_name=None, panel_logo=None):
    creds = get_panel_creds()
    creds["PANEL_USER"] = user
    creds["PANEL_PASS_PLAIN"] = pass_plain
    creds["PANEL_PASS_HASH"] = hashlib.sha256(pass_plain.encode()).hexdigest()
    if secret is not None:
        creds["PANEL_SECRET"] = secret.strip().lstrip('/')
    if panel_name is not None:
        creds["PANEL_NAME"] = panel_name.strip() or DEFAULT_PANEL_NAME
    if panel_logo is not None:
        creds["PANEL_LOGO"] = panel_logo.strip() or "🦅"
    
    os.makedirs(os.path.dirname(PANEL_CONF), exist_ok=True)
    with open(PANEL_CONF, "w") as f:
        for k, v in creds.items():
            f.write(f"{k}={v}\n")

# --- SESSION ---
def cleanup_sessions():
    now = time.time()
    expired = [t for t, s in sessions.items() if now - s["created_at"] > 86400]
    for t in expired:
        del sessions[t]
    if expired:
        save_sessions()

def generate_password(length=8):
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return "".join(secrets.choice(chars) for _ in range(length))

def calculate_expire_date(days):
    return (datetime.now() + timedelta(days=days)).strftime("%Y-%m-%d")

def check_session(headers):
    """Returns session info dict or None if not authenticated."""
    cleanup_sessions()
    if "Cookie" in headers:
        C = cookies.SimpleCookie(headers["Cookie"])
        if "session" in C:
            token = C["session"].value
            if token in sessions:
                return sessions[token]
    return None

# --- HTTP HANDLER ---

# --- V2RAY (XRAY) MANAGEMENT ------------------------------------------------
# The panel reuses the SAME manager as the menu (ffv2ray.py): reads go through the module,
# changes go through its CLI, so locking, Xray config rendering and limits behave identically.
V2_MANAGER = os.environ.get("PANEL_V2_MANAGER", "/usr/local/lib/visibleTech-v2ray/ffv2ray.py")
V2_DATA_DIR = os.environ.get("FFV2_DIR", DB_DIR + "/v2ray")
V2_NAME_RE = re.compile(r'^[A-Za-z0-9_-]{2,24}$')
V2_PROTOS = ("vmess", "vless", "trojan")
V2_LIMITER_SERVICE = "ff-v2ray-limiter"
_v2_mod = None
_ANSI_RE = re.compile(r'\x1b\[[0-9;]*[A-Za-z]')

def v2_installed():
    return os.path.isfile(V2_MANAGER) and os.path.isfile(os.path.join(V2_DATA_DIR, "settings.json"))

def v2_module():
    """Load ffv2ray.py once (it reads FFV2_DIR when it is imported)."""
    global _v2_mod
    if _v2_mod is not None:
        return _v2_mod
    if not os.path.isfile(V2_MANAGER):
        return None
    os.environ["FFV2_DIR"] = V2_DATA_DIR
    os.environ["NO_COLOR"] = "1"
    import importlib.util
    spec = importlib.util.spec_from_file_location("ffv2ray_manager", V2_MANAGER)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    _v2_mod = mod
    return mod

def v2_cli(args, timeout=90):
    env = dict(os.environ, FFV2_DIR=V2_DATA_DIR, NO_COLOR="1")
    try:
        p = subprocess.run([sys.executable, V2_MANAGER] + [str(a) for a in args],
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
                           timeout=timeout, universal_newlines=True)
        return p.returncode, _ANSI_RE.sub("", p.stdout or "").strip(), _ANSI_RE.sub("", p.stderr or "").strip()
    except Exception as e:
        return -1, "", str(e)

def v2_num(v, default=0.0, lo=0.0, hi=100000.0):
    try:
        x = float(v)
    except (TypeError, ValueError):
        return default
    if x != x:
        return default
    return max(lo, min(hi, x))

def v2_fmt(x):
    return ("%g" % x)

def v2_summary(mod, name, u, usage, now):
    usg = usage["users"].get(name, {})
    status = mod.user_status(u, usg, now)
    tl = mod.quota_bytes(u.get("total_gb", 0))
    dl = mod.quota_bytes(u.get("daily_gb", 0))
    used, today = int(usg.get("total", 0)), int(usg.get("daily", 0))
    return {
        "name": name, "proto": u.get("proto"), "status": status,
        "status_text": mod.STATUS_TEXT.get(status, (status,))[0],
        "locked": bool(u.get("locked")), "trial": bool(u.get("trial")),
        "conn_limit": mod.user_conn_limit(u), "owner": u.get("owner", "admin"),
        "created": u.get("created", 0), "expiry": u.get("expiry", 0),
        "expiry_text": mod.fmt_time(u["expiry"]) if u.get("expiry") else "Never",
        "total_gb": u.get("total_gb", 0), "daily_gb": u.get("daily_gb", 0),
        "used": used, "today": today,
        "up": int(usg.get("up", 0)), "down": int(usg.get("down", 0)),
        "rate_up": int(usg.get("rate_up", 0)), "rate_down": int(usg.get("rate_down", 0)),
        "pct_total": round(min(100.0, used * 100.0 / tl), 1) if tl > 0 else None,
        "pct_daily": round(min(100.0, today * 100.0 / dl), 1) if dl > 0 else None,
    }

class PanelAPIHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress default logging

    def send_json(self, status, data, extra_headers=None):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        if extra_headers:
            for k, v in extra_headers.items():
                self.send_header(k, v)
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def _get_session(self):
        """Helper: returns session dict or sends 401 and returns None."""
        s = check_session(self.headers)
        if not s:
            self.send_json(401, {"error": "Unauthorized"})
        return s

    def _require_admin(self, session):
        """Helper: returns True if admin, else sends 403 and returns False."""
        if session.get("role") != "admin":
            self.send_json(403, {"error": "Admin access required"})
            return False
        return True

    def do_GET(self):
        try:
            parsed_path = urlparse(self.path)
            raw_path = parsed_path.path.strip()
            creds = get_panel_creds()
            secret = creds.get("PANEL_SECRET", "").strip().lstrip('/')
            
            # Check secret path matching for HTML serving
            is_html_request = False
            if not secret:
                if raw_path in ("/", "/index.html"):
                    is_html_request = True
            else:
                valid_paths = (f"/{secret}", f"/{secret}/", f"/{secret}/index.html")
                if raw_path in valid_paths:
                    is_html_request = True

            if is_html_request:
                if os.path.exists(PANEL_HTML):
                    with open(PANEL_HTML, "rb") as f:
                        content = f.read()
                    self.send_response(200)
                    self.send_header('Content-Type', 'text/html; charset=utf-8')
                    self.end_headers()
                    self.wfile.write(content)
                else:
                    msg = ("Panel page missing: " + PANEL_HTML + "\n"
                           "Run the menu: Web Control Panel > Repair / update panel files.\n").encode()
                    self.send_response(404)
                    self.send_header('Content-Type', 'text/plain; charset=utf-8')
                    self.end_headers()
                    self.wfile.write(msg)
                return

            # Clean API path if prefixed with secret
            api_path = raw_path
            if secret and api_path.startswith(f"/{secret}/api/"):
                api_path = api_path[len(secret) + 1:]
            
            if not api_path.startswith("/api/"):
                self.send_response(404)
                self.send_header('Content-Type', 'text/plain; charset=utf-8')
                self.end_headers()
                if secret:
                    self.wfile.write(b"404 Not Found\nOpen the full panel link (with the secret path) shown in the menu:\nWeb Control Panel > Show Panel Credentials\n")
                else:
                    self.wfile.write(b"404 Not Found\n")
                return

            # Public endpoint: branding (no auth required)
            if api_path == "/api/branding":
                creds = get_panel_creds()
                self.send_json(200, {
                    "panel_name": creds.get("PANEL_NAME", DEFAULT_PANEL_NAME),
                    "panel_logo": creds.get("PANEL_LOGO", "\ud83e\udd85"),
                    "has_custom_logo": os.path.exists(LOGO_PATH) and creds.get("PANEL_LOGO") == "custom"
                })
                return

            # Serve custom logo image (public, no auth)
            logo_path = LOGO_PATH
            if api_path == "/api/logo.png":
                if os.path.exists(logo_path):
                    with open(logo_path, "rb") as f:
                        img_data = f.read()
                    self.send_response(200)
                    self.send_header('Content-Type', 'image/png')
                    self.send_header('Cache-Control', 'public, max-age=3600')
                    self.end_headers()
                    self.wfile.write(img_data)
                else:
                    self.send_response(404)
                    self.end_headers()
                    self.wfile.write(b"No custom logo")
                return

            session = self._get_session()
            if not session:
                return

            if api_path == "/api/me":
                self.handle_get_me(session)
            elif api_path == "/api/dashboard":
                self.handle_get_dashboard(session)
            elif api_path == "/api/users":
                self.handle_get_users(session)
            elif api_path == "/api/protocols":
                if not self._require_admin(session):
                    return
                self.handle_get_protocols()
            elif api_path == "/api/settings":
                if not self._require_admin(session):
                    return
                self.handle_get_settings()
            elif api_path == "/api/resellers":
                if not self._require_admin(session):
                    return
                self.handle_get_resellers()
            elif api_path.startswith("/api/v2ray/"):
                actor = self._v2_actor(session)
                if actor is None:
                    return
                self.handle_v2_get(api_path, parse_qs(parsed_path.query), actor)
            else:
                self.send_json(404, {"error": "Not Found"})
        except Exception as e:
            print(f"Error handling GET {self.path}: {e}", file=sys.stderr)
            self.send_json(500, {"error": str(e)})

    def do_POST(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        content_length = int(self.headers.get('Content-Length', 0))
        
        # Handle logo upload BEFORE reading body as JSON (binary upload)
        if path == "/api/logo/upload":
            session = self._get_session()
            if not session:
                return
            if not self._require_admin(session):
                return
            raw_data = self.rfile.read(content_length) if content_length > 0 else b''
            self.handle_logo_upload(raw_data)
            return
        
        post_data = self.rfile.read(content_length)
        try:
            body = json.loads(post_data.decode('utf-8')) if post_data else {}
        except json.JSONDecodeError:
            body = {}

        if path == "/api/login":
            self.handle_login(body)
            return

        session = self._get_session()
        if not session:
            return

        if path == "/api/logout":
            self.handle_logout()
        elif path == "/api/logo/delete":
            if not self._require_admin(session):
                return
            self.handle_logo_delete()
        elif path == "/api/users":
            self.handle_post_users(body, session)
        elif path == "/api/users/bulk":
            self.handle_post_users_bulk(body, session)
        elif path.startswith("/api/users/") and path.endswith("/lock"):
            user = path.split("/")[3]
            self.handle_user_action(user, "lock", session=session)
        elif path.startswith("/api/users/") and path.endswith("/unlock"):
            user = path.split("/")[3]
            self.handle_user_action(user, "unlock", session=session)
        elif path.startswith("/api/users/") and path.endswith("/renew"):
            user = path.split("/")[3]
            self.handle_user_action(user, "renew", body=body, session=session)
        elif path.startswith("/api/users/") and path.endswith("/reset-bandwidth"):
            user = path.split("/")[3]
            self.handle_user_action(user, "reset-bandwidth", session=session)
        elif path.startswith("/api/protocols/") and path.endswith("/restart"):
            if not self._require_admin(session):
                return
            service = path.split("/")[3]
            self.handle_protocol_restart(service)
        elif path == "/api/users/trial":
            self.handle_post_trial_user(body, session)
        elif path == "/api/resellers":
            if not self._require_admin(session):
                return
            self.handle_post_reseller(body)
        elif path == "/api/system/reboot":
            if not self._require_admin(session):
                return
            self.handle_system_reboot()
        elif path.startswith("/api/resellers/") and path.endswith("/toggle"):
            if not self._require_admin(session):
                return
            reseller_name = path.split("/")[3]
            self.handle_toggle_reseller(reseller_name)
        elif path.startswith("/api/v2ray/"):
            actor = self._v2_actor(session)
            if actor is None:
                return
            self.handle_v2_post(path, body, actor)
        else:
            self.send_json(404, {"error": "Not Found"})

    def do_PUT(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        session = self._get_session()
        if not session:
            return

        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        try:
            body = json.loads(post_data.decode('utf-8')) if post_data else {}
        except json.JSONDecodeError:
            body = {}

        if path.startswith("/api/users/"):
            user = path.split("/")[3]
            self.handle_put_user(user, body, session)
        elif path == "/api/settings":
            if not self._require_admin(session):
                return
            self.handle_put_settings(body)
        elif path.startswith("/api/resellers/"):
            if not self._require_admin(session):
                return
            reseller_name = path.split("/")[3]
            self.handle_put_reseller(reseller_name, body)
        else:
            self.send_json(404, {"error": "Not Found"})

    def do_DELETE(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        session = self._get_session()
        if not session:
            return

        if path.startswith("/api/resellers/"):
            if not self._require_admin(session):
                return
            reseller_name = path.split("/")[3]
            # Check query params for delete_users flag
            qs = parse_qs(urlparse(self.path).query)
            delete_users = qs.get("delete_users", ["0"])[0] == "1"
            self.handle_delete_reseller(reseller_name, delete_users)
        elif path.startswith("/api/v2ray/"):
            actor = self._v2_actor(session)
            if actor is None:
                return
            self.handle_v2_delete(path, actor)
        elif path.startswith("/api/users/"):
            user = path.split("/")[3]
            self.handle_delete_user(user, session)
        else:
            self.send_json(404, {"error": "Not Found"})

    # --- OWNERSHIP CHECK ---
    def _check_user_ownership(self, username, session):
        """Check if the session owner can manage this user. Returns True if allowed."""
        if session.get("role") == "admin":
            return True
        # Reseller can only manage their own users
        users = read_db()
        user = next((u for u in users if u["username"] == username), None)
        if not user:
            return False
        return user.get("owner", "admin") == session.get("username")

    # --- HANDLERS ---
    def handle_login(self, body):
        user = body.get("username", "")
        pwd = body.get("password", "")
        pwd_hash = hashlib.sha256(pwd.encode()).hexdigest()
        
        # Check admin credentials first
        creds = get_panel_creds()
        if user == creds.get("PANEL_USER") and pwd_hash == creds.get("PANEL_PASS_HASH"):
            token = secrets.token_hex(32)
            sessions[token] = {"username": user, "role": "admin", "created_at": time.time()}
            save_sessions()
            cookie_str = f"session={token}; Path=/; HttpOnly; Max-Age=86400"
            self.send_json(200, {"success": True, "role": "admin"}, {"Set-Cookie": cookie_str})
            return

        # Check reseller credentials
        resellers = read_resellers()
        for r in resellers:
            if r["username"] == user and r["password"] == pwd:
                if not r["enabled"]:
                    return self.send_json(401, {"error": "Account is disabled"})
                # Check reseller expiry
                try:
                    exp = datetime.strptime(r["expire_date"], "%Y-%m-%d")
                    if exp < datetime.now():
                        return self.send_json(401, {"error": "Account has expired"})
                except ValueError:
                    pass
                token = secrets.token_hex(32)
                sessions[token] = {"username": user, "role": "reseller", "created_at": time.time()}
                save_sessions()
                cookie_str = f"session={token}; Path=/; HttpOnly; Max-Age=86400"
                self.send_json(200, {"success": True, "role": "reseller"}, {"Set-Cookie": cookie_str})
                return

        self.send_json(401, {"error": "Invalid credentials"})

    def handle_logout(self):
        if "Cookie" in self.headers:
            C = cookies.SimpleCookie(self.headers["Cookie"])
            if "session" in C:
                token = C["session"].value
                if token in sessions:
                    del sessions[token]
                    save_sessions()
        cookie_str = f"session=; Path=/; HttpOnly; Max-Age=0"
        self.send_json(200, {"success": True}, {"Set-Cookie": cookie_str})

    def handle_get_me(self, session):
        creds = get_panel_creds()
        data = {
            "role": session.get("role", "admin"),
            "username": session.get("username", ""),
            "panel_name": creds.get("PANEL_NAME", DEFAULT_PANEL_NAME),
            "panel_logo": creds.get("PANEL_LOGO", "🦅"),
            "has_custom_logo": os.path.exists(LOGO_PATH) and creds.get("PANEL_LOGO") == "custom"
        }
        if session.get("role") == "reseller":
            resellers = read_resellers()
            r = next((x for x in resellers if x["username"] == session["username"]), None)
            if r:
                data["expire_date"] = r["expire_date"]
                data["max_users"] = r["max_users"]
                data["max_conn"] = r.get("max_conn", 0)
                data["reseller_type"] = r["rtype"]
                data["allowed_protos"] = reseller_protos(r)
                if r["rtype"] == "v2ray":
                    data["created_users"] = len(v2_owned_names(session["username"]))
                else:
                    users = read_db()
                    owned = [u for u in users if u.get("owner") == session["username"]]
                    data["created_users"] = len(owned)
        self.send_json(200, data)

    def handle_get_dashboard(self, session):
        users = read_db()

        if session.get("role") == "reseller":
            # Reseller sees only their stats
            r = get_reseller(session)
            rtype = r["rtype"] if r else "ssh"
            if rtype == "v2ray":
                names = v2_owned_names(session["username"])
                om = v2_online_map()
                online_total = sum(om[n]["devices"] for n in names if n in om)
                created = len(names)
            else:
                owned_users = [u for u in users if u.get("owner") == session["username"]]
                owned_usernames = set(u["username"] for u in owned_users)
                online_pids = get_online_sessions_for_users(owned_usernames)
                online_total = sum(len(pids) for pids in online_pids.values())
                created = len(owned_users)

            self.send_json(200, {
                "user_count": created,
                "online_sessions": online_total,
                "protocols": [],
                "reseller_info": {
                    "max_users": r["max_users"] if r else 0,
                    "max_conn": r.get("max_conn", 0) if r else 0,
                    "created_users": created,
                    "expire_date": r["expire_date"] if r else "N/A",
                    "type": rtype,
                    "protos": reseller_protos(r)
                }
            })
            return

        # --- ADMIN BRANCH ---
        _, ip, _ = run_cmd("curl -s -4 --max-time 3 icanhazip.com")
        
        os_name = "Unknown OS"
        try:
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("PRETTY_NAME="):
                        os_name = line.split("=")[1].strip().strip('"')
                        break
        except Exception:
            pass

        _, uptime_str, _ = run_cmd("uptime -p")
        if uptime_str.startswith("up "):
            uptime_str = uptime_str[3:]

        ram_total = 0
        ram_available = 0
        try:
            with open("/proc/meminfo") as f:
                for line in f:
                    if line.startswith("MemTotal:"):
                        ram_total = int(line.split()[1]) // 1024
                    elif line.startswith("MemAvailable:"):
                        ram_available = int(line.split()[1]) // 1024
        except Exception:
            pass
        ram_used = ram_total - ram_available if ram_total > 0 else 0
        ram_percent = round((ram_used / ram_total) * 100, 1) if ram_total > 0 else 0.0

        cpu_load = 0.0
        try:
            with open("/proc/loadavg") as f:
                cpu_load = float(f.read().split()[0])
        except Exception:
            pass

        # Admin sees everything
        online_ssh = get_online_sessions()
        v2_users = v2_users_safe()
        v2_online = v2_online_map()
        online_v2 = sum(v["devices"] for n, v in v2_online.items() if n in v2_users)
        online_sessions = online_ssh + online_v2
        procs = self.get_protocols_status()
        self.send_json(200, {
            "server_ip": ip,
            "os_name": os_name,
            "uptime": uptime_str,
            "ram_percent": ram_percent,
            "ram_used_mb": ram_used,
            "ram_total_mb": ram_total,
            "cpu_load_1m": cpu_load,
            "user_count": len(users) + len(v2_users),
            "ssh_count": len(users),
            "v2ray_count": len(v2_users),
            "online_sessions": online_sessions,
            "online_ssh": online_ssh,
            "online_v2ray": online_v2,
            "protocols": procs
        })

    def get_protocols_status(self):
        procs = []
        for p in PROTOCOLS:
            installed = False
            if p["check_file"] is None:
                installed = True
            else:
                installed = os.path.exists(p["check_file"])
                
            running = False
            if installed:
                code, _, _ = run_cmd(["systemctl", "is-active", p["service"]])
                if code == 0:
                    running = True
                elif "service_alt" in p:
                    code2, _, _ = run_cmd(["systemctl", "is-active", p["service_alt"]])
                    if code2 == 0:
                        running = True
                        
            port_txt = p["port"]
            if "port_conf" in p:
                val = conf_value(*p["port_conf"]).replace(" ", ",")
                if val:
                    port_txt = val
            procs.append({
                "name": p["name"],
                "service": p["service"],
                "installed": installed,
                "running": running,
                "port": port_txt
            })
        return procs

    def handle_get_users(self, session):
        users = read_db()
        
        # Scope by role
        if session.get("role") == "reseller":
            users = [u for u in users if u.get("owner") == session["username"]]

        # Efficient batch online session lookup
        all_usernames = set(u["username"] for u in users)
        online_pids = get_online_sessions_for_users(all_usernames)

        result = []
        for u in users:
            un = u["username"]
            total_bw = read_file_int(f"{BW_DIR}/{un}.usage")
            daily_bw = read_file_int(f"{BW_DIR}/{un}.daily_usage")
            
            code, out, _ = run_cmd(["passwd", "-S", un])
            is_locked = False
            if code == 0 and len(out.split()) >= 2:
                is_locked = (out.split()[1] == "L")
                
            code2, _, _ = run_cmd(["id", un])
            exists_on_system = (code2 == 0)
            
            is_expired = False
            try:
                if u["expire_date"] != "Never" and u["expire_date"]:
                    exp_date = datetime.strptime(u["expire_date"], "%Y-%m-%d")
                    is_expired = exp_date < datetime.now()
            except ValueError:
                pass
            
            online_count = len(online_pids.get(un, set()))
            
            u_ext = dict(u)
            u_ext["total_used_bytes"] = total_bw
            u_ext["daily_used_bytes"] = daily_bw
            u_ext["is_locked"] = is_locked
            u_ext["is_expired"] = is_expired
            u_ext["is_online"] = online_count > 0
            u_ext["online_sessions"] = online_count
            u_ext["exists_on_system"] = exists_on_system
            
            result.append(u_ext)
            
        self.send_json(200, {"users": result})

    def _create_user(self, un, pwd, days, conn, bw, dbw, acct_type="web", owner="admin"):
        if not re.match(r'^[a-zA-Z0-9_]{3,32}$', un):
            raise ValueError("Invalid username")
            
        if any(u["username"] == un for u in read_db()):
            raise ValueError("User already exists in DB")
            
        code, _, _ = run_cmd(["id", un])
        if code == 0:
            raise ValueError("User already exists on system")

        run_cmd(["useradd", "-m", "-s", "/usr/sbin/nologin", un])
        run_cmd(["usermod", "-aG", FF_USERS_GROUP, un], ignore_errors=True)
        run_cmd(f"echo '{un}:{pwd}' | chpasswd")
        
        exp_date_str = calculate_expire_date(days)
        run_cmd(["chage", "-E", exp_date_str, un])
        
        new_u = {
            "username": un,
            "password": pwd,
            "expire_date": exp_date_str,
            "conn_limit": conn,
            "bandwidth_gb": bw,
            "daily_bandwidth_gb": dbw,
            "account_type": acct_type,
            "owner": owner
        }
        
        with db_lock:
            os.makedirs(os.path.dirname(DB_FILE), exist_ok=True)
            with open(DB_FILE, "a") as f:
                f.write(format_db_line(new_u))
        
        # Initialize bandwidth usage files to prevent immediate locking
        os.makedirs(BW_DIR, exist_ok=True)
        with open(f"{BW_DIR}/{un}.usage", "w") as f:
            f.write("0")
        with open(f"{BW_DIR}/{un}.daily_usage", "w") as f:
            f.write("0")
                
        refresh_ssh_banner_config()
        return new_u

    def handle_post_users(self, body, session):
        try:
            owner = session.get("username", "admin") if session.get("role") == "reseller" else "admin"

            # Reseller quota check
            if session.get("role") == "reseller":
                resellers = read_resellers()
                r = next((x for x in resellers if x["username"] == session["username"]), None)
                if not r:
                    return self.send_json(403, {"error": "Reseller account not found"})
                if r.get("rtype", "ssh") != "ssh":
                    return self.send_json(403, {"error": "Your reseller account can only create V2Ray accounts"})
                users = read_db()
                owned = [u for u in users if u.get("owner") == session["username"]]
                if len(owned) >= r["max_users"]:
                    return self.send_json(403, {"error": f"User limit reached ({r['max_users']})"})

            un = body.get("username", "")
            pwd = body.get("password", "") or generate_password()
            days = int(body.get("days", 30))
            conn = int(body.get("conn_limit", 1))
            bw = float(body.get("bandwidth_gb", 0))
            dbw = float(body.get("daily_bandwidth_gb", 0))

            if session.get("role") == "reseller":
                err = reseller_conn_error(r, conn)
                if err:
                    return self.send_json(403, {"error": err})
            
            new_u = self._create_user(un, pwd, days, conn, bw, dbw, owner=owner)
            self.send_json(200, new_u)
        except Exception as e:
            self.send_json(400, {"error": str(e)})

    def handle_post_users_bulk(self, body, session):
        try:
            owner = session.get("username", "admin") if session.get("role") == "reseller" else "admin"
            
            # Reseller quota check
            remaining_quota = float('inf')
            if session.get("role") == "reseller":
                resellers = read_resellers()
                r = next((x for x in resellers if x["username"] == session["username"]), None)
                if not r:
                    return self.send_json(403, {"error": "Reseller account not found"})
                if r.get("rtype", "ssh") != "ssh":
                    return self.send_json(403, {"error": "Your reseller account can only create V2Ray accounts"})
                users = read_db()
                owned = [u for u in users if u.get("owner") == session["username"]]
                remaining_quota = r["max_users"] - len(owned)
                if remaining_quota <= 0:
                    return self.send_json(403, {"error": f"User limit reached ({r['max_users']})"})

            prefix = body.get("prefix", "user")
            count = min(int(body.get("count", 1)), int(remaining_quota))
            days = int(body.get("days", 30))
            conn = int(body.get("conn_limit", 1))
            bw = float(body.get("bandwidth_gb", 0))
            dbw = float(body.get("daily_bandwidth_gb", 0))

            if session.get("role") == "reseller":
                err = reseller_conn_error(r, conn)
                if err:
                    return self.send_json(403, {"error": err})
            
            created = []
            existing_users = set(u["username"] for u in read_db())
            
            idx = 1
            for _ in range(count):
                while f"{prefix}{idx}" in existing_users:
                    idx += 1
                un = f"{prefix}{idx}"
                pwd = generate_password()
                
                try:
                    u = self._create_user(un, pwd, days, conn, bw, dbw, "bulk", owner=owner)
                    created.append(u)
                    existing_users.add(un)
                except Exception as e:
                    pass # skip failures in bulk
                idx += 1
                
            self.send_json(200, {"users": created})
        except Exception as e:
            self.send_json(400, {"error": str(e)})

    def handle_post_trial_user(self, body, session):
        try:
            owner = session.get("username", "admin") if session.get("role") == "reseller" else "admin"

            # Reseller quota check
            if session.get("role") == "reseller":
                resellers = read_resellers()
                r = next((x for x in resellers if x["username"] == session["username"]), None)
                if not r:
                    return self.send_json(403, {"error": "Reseller account not found"})
                if r.get("rtype", "ssh") != "ssh":
                    return self.send_json(403, {"error": "Your reseller account can only create V2Ray accounts"})
                users = read_db()
                owned = [u for u in users if u.get("owner") == session["username"]]
                if len(owned) >= r["max_users"]:
                    return self.send_json(403, {"error": f"User limit reached ({r['max_users']})"})

            un = body.get("username", "")
            if not un:
                import random, string
                un = "trial_" + "".join(random.choices(string.ascii_lowercase + string.digits, k=5))
            pwd = body.get("password", "") or generate_password()
            hours = int(body.get("hours", 1))
            conn = int(body.get("conn_limit", 1))
            bw = float(body.get("bandwidth_gb", 0))

            if session.get("role") == "reseller":
                err = reseller_conn_error(r, conn)
                if err:
                    return self.send_json(403, {"error": err})
            
            # Calculate days for expiry
            if hours >= 24:
                days = hours // 24
            else:
                days = 1  # At least 1 day for chage, at job does real cleanup
            
            new_u = self._create_user(un, pwd, days, conn, bw, 0, acct_type="trial", owner=owner)
            
            # Schedule auto-cleanup via 'at' daemon
            cleanup_script = TRIAL_CLEANUP_SCRIPT
            if os.path.exists(cleanup_script):
                run_cmd(f"echo '{cleanup_script} {un}' | at now + {hours} hours", ignore_errors=True)
            
            # Calculate expiry timestamp for display
            from datetime import datetime, timedelta
            expiry_time = (datetime.now() + timedelta(hours=hours)).strftime("%Y-%m-%d %H:%M:%S")
            new_u["expiry_time"] = expiry_time
            new_u["hours"] = hours
            
            self.send_json(200, new_u)
        except Exception as e:
            self.send_json(400, {"error": str(e)})

    def handle_put_user(self, username, body, session):
        if not self._check_user_ownership(username, session):
            return self.send_json(403, {"error": "Access denied"})

        with db_lock:
            users = read_db()
            idx = next((i for i, u in enumerate(users) if u["username"] == username), -1)
            if idx == -1:
                return self.send_json(404, {"error": "User not found"})
                
            u = users[idx]
            
            if "password" in body:
                u["password"] = body["password"]
                run_cmd(f"echo '{username}:{u['password']}' | chpasswd")
                
            if "days" in body:
                u["expire_date"] = calculate_expire_date(int(body["days"]))
                run_cmd(["chage", "-E", u["expire_date"], username])
                
            if "conn_limit" in body:
                new_conn = int(body["conn_limit"])
                if session.get("role") == "reseller":
                    err = reseller_conn_error(get_reseller(session), new_conn)
                    if err:
                        return self.send_json(403, {"error": err})
                u["conn_limit"] = new_conn
                
            if "bandwidth_gb" in body:
                u["bandwidth_gb"] = float(body["bandwidth_gb"])
                
            if "daily_bandwidth_gb" in body:
                u["daily_bandwidth_gb"] = float(body["daily_bandwidth_gb"])

            lines = []
            with open(DB_FILE, "r") as f:
                lines = f.readlines()
                
            with open(DB_FILE, "w") as f:
                for line in lines:
                    if line.startswith(f"{username}:"):
                        f.write(format_db_line(u))
                    else:
                        f.write(line)
                        
            self.send_json(200, u)

    def handle_delete_user(self, username, session):
        if not self._check_user_ownership(username, session):
            return self.send_json(403, {"error": "Access denied"})

        force_delete_system_user(username)
        
        with db_lock:
            lines = []
            if os.path.exists(DB_FILE):
                with open(DB_FILE, "r") as f:
                    lines = f.readlines()
                with open(DB_FILE, "w") as f:
                    for line in lines:
                        if not line.startswith(f"{username}:"):
                            f.write(line)
                            
        run_cmd(f"rm -f {BW_DIR}/{username}.*", ignore_errors=True)
        run_cmd(f"rm -f {BANNER_DIR}/{username}.txt", ignore_errors=True)
        refresh_ssh_banner_config()
        
        self.send_json(200, {"success": True})

    def handle_user_action(self, username, action, body=None, session=None):
        if not self._check_user_ownership(username, session):
            return self.send_json(403, {"error": "Access denied"})

        if action == "lock":
            run_cmd(["usermod", "-L", username])
            run_cmd(["killall", "-u", username, "-9"], ignore_errors=True)
            self.send_json(200, {"success": True})
            
        elif action == "unlock":
            run_cmd(["usermod", "-U", username])
            run_cmd(f"rm -f {BW_DIR}/{username}.conn_locked", ignore_errors=True)
            run_cmd(f"rm -f {BW_DIR}/{username}.daily_locked", ignore_errors=True)
            self.send_json(200, {"success": True})
            
        elif action == "renew":
            days = int(body.get("days", 30)) if body else 30
            with db_lock:
                users = read_db()
                u = next((x for x in users if x["username"] == username), None)
                if not u:
                    return self.send_json(404, {"error": "User not found"})
                u["expire_date"] = calculate_expire_date(days)
                run_cmd(["chage", "-E", u["expire_date"], username])
                
                lines = []
                with open(DB_FILE, "r") as f:
                    lines = f.readlines()
                with open(DB_FILE, "w") as f:
                    for line in lines:
                        if line.startswith(f"{username}:"):
                            f.write(format_db_line(u))
                        else:
                            f.write(line)
            self.send_json(200, {"success": True, "expire_date": u["expire_date"]})
            
        elif action == "reset-bandwidth":
            os.makedirs(BW_DIR, exist_ok=True)
            with open(f"{BW_DIR}/{username}.usage", "w") as f:
                f.write("0")
            with open(f"{BW_DIR}/{username}.daily_usage", "w") as f:
                f.write("0")
            run_cmd(f"rm -f {BW_DIR}/{username}.conn_locked", ignore_errors=True)
            run_cmd(f"rm -f {BW_DIR}/{username}.daily_locked", ignore_errors=True)
            run_cmd(["usermod", "-U", username])
            self.send_json(200, {"success": True})
            
        else:
            self.send_json(400, {"error": "Unknown action"})

    def handle_get_protocols(self):
        self.send_json(200, self.get_protocols_status())

    def handle_protocol_restart(self, service):
        code, out, err = run_cmd(["systemctl", "restart", service])
        if code == 0:
            self.send_json(200, {"success": True})
        else:
            self.send_json(500, {"success": False, "error": err})

    def handle_system_reboot(self):
        self.send_json(200, {"success": True, "message": "Rebooting system..."})
        # Schedule reboot in background so we can return response first
        threading.Timer(2.0, lambda: subprocess.run(["reboot"])).start()

    def handle_logo_upload(self, raw_data):
        try:
            if len(raw_data) > 2097152:  # 2MB max
                return self.send_json(400, {"error": "File too large (max 2MB)"})
            if len(raw_data) == 0:
                return self.send_json(400, {"error": "No file data"})
            
            logo_path = LOGO_PATH
            os.makedirs(os.path.dirname(logo_path), exist_ok=True)
            with open(logo_path, "wb") as f:
                f.write(raw_data)
            
            # Set PANEL_LOGO to 'custom' to signal frontend to use image
            creds = get_panel_creds()
            creds["PANEL_LOGO"] = "custom"
            os.makedirs(os.path.dirname(PANEL_CONF), exist_ok=True)
            with open(PANEL_CONF, "w") as f:
                for k, v in creds.items():
                    f.write(f"{k}={v}\n")
            
            self.send_json(200, {"success": True, "panel_logo": "custom"})
        except Exception as e:
            self.send_json(500, {"error": str(e)})

    def handle_logo_delete(self):
        logo_path = LOGO_PATH
        try:
            if os.path.exists(logo_path):
                os.remove(logo_path)
            creds = get_panel_creds()
            creds["PANEL_LOGO"] = "🦅"
            os.makedirs(os.path.dirname(PANEL_CONF), exist_ok=True)
            with open(PANEL_CONF, "w") as f:
                for k, v in creds.items():
                    f.write(f"{k}={v}\n")
            self.send_json(200, {"success": True, "panel_logo": "🦅"})
        except Exception as e:
            self.send_json(500, {"error": str(e)})

    def handle_get_settings(self):
        creds = get_panel_creds()
        self.send_json(200, {
            "username": creds.get("PANEL_USER", ""),
            "secret": creds.get("PANEL_SECRET", ""),
            "panel_name": creds.get("PANEL_NAME", DEFAULT_PANEL_NAME),
            "panel_logo": creds.get("PANEL_LOGO", "🦅"),
            "has_custom_logo": os.path.exists(LOGO_PATH) and creds.get("PANEL_LOGO") == "custom"
        })

    def handle_put_settings(self, body):
        creds = get_panel_creds()
        curr_pwd = body.get("current_password", "")
        new_user = body.get("new_username", "").strip() or creds.get("PANEL_USER", "")
        new_pwd = body.get("new_password", "").strip() or creds.get("PANEL_PASS_PLAIN", "")
        new_secret = body.get("new_secret", "").strip().lstrip('/')
        new_name = body.get("panel_name", "").strip()
        new_logo = body.get("panel_logo", "").strip()
        
        curr_hash = hashlib.sha256(curr_pwd.encode()).hexdigest()
        if curr_hash != creds.get("PANEL_PASS_HASH"):
            return self.send_json(401, {"error": "Invalid current password"})
            
        write_panel_creds(new_user, new_pwd, secret=new_secret, panel_name=new_name or None, panel_logo=new_logo or None)
        self.send_json(200, {"success": True, "secret": new_secret, "panel_name": new_name or creds.get("PANEL_NAME", DEFAULT_PANEL_NAME), "panel_logo": new_logo or creds.get("PANEL_LOGO", "🦅")})

    # --- RESELLER HANDLERS (admin only) ---
    def handle_get_resellers(self):
        resellers = read_resellers()
        users = read_db()
        v2_users = v2_users_safe()
        result = []
        for r in resellers:
            if r["rtype"] == "v2ray":
                created = len(v2_owned_names(r["username"], v2_users))
            else:
                created = len([u for u in users if u.get("owner") == r["username"]])
            is_expired = False
            try:
                exp = datetime.strptime(r["expire_date"], "%Y-%m-%d")
                is_expired = exp < datetime.now()
            except ValueError:
                pass
            result.append({
                "username": r["username"],
                "password": r["password"],
                "expire_date": r["expire_date"],
                "max_users": r["max_users"],
                "max_conn": r.get("max_conn", 0),
                "created_users": created,
                "enabled": r["enabled"],
                "is_expired": is_expired,
                "type": r["rtype"],
                "protos": r["protos"]
            })
        self.send_json(200, {"resellers": result})

    def handle_post_reseller(self, body):
        try:
            un = body.get("username", "").strip()
            pwd = body.get("password", "") or generate_password()
            days = int(body.get("days", 30))
            max_users = int(body.get("max_users", 10))
            max_conn = int(body.get("max_conn", 0) or 0)
            if max_users < 1:
                return self.send_json(400, {"error": "Max accounts must be at least 1"})
            if max_conn < 0 or max_conn > 1000:
                return self.send_json(400, {"error": "Max connections per account must be 0-1000 (0 = no limit)"})
            rtype = str(body.get("type", "ssh")).strip().lower()

            if not re.match(r'^[a-zA-Z0-9_]{3,32}$', un):
                return self.send_json(400, {"error": "Invalid username (3-32 chars, alphanumeric + underscore)"})
            if rtype not in RESELLER_TYPES:
                return self.send_json(400, {"error": "Reseller type must be SSH or V2Ray"})
            if rtype == "v2ray":
                protos = norm_protos(body.get("protos", ["all"]))
                if not protos:
                    return self.send_json(400, {"error": "Choose at least one V2Ray protocol"})
            else:
                protos = []

            # Check conflicts with admin username
            creds = get_panel_creds()
            if un == creds.get("PANEL_USER") or un.lower() == "admin":
                return self.send_json(400, {"error": "Username conflicts with admin"})

            resellers = read_resellers()
            if any(r["username"] == un for r in resellers):
                return self.send_json(400, {"error": "Reseller already exists"})

            new_r = {
                "username": un,
                "password": pwd,
                "expire_date": calculate_expire_date(days),
                "max_users": max_users,
                "max_conn": max_conn,
                "enabled": True,
                "rtype": rtype,
                "protos": protos
            }
            resellers.append(new_r)
            write_resellers(resellers)
            self.send_json(200, dict(new_r, type=rtype))
        except Exception as e:
            self.send_json(400, {"error": str(e)})

    def handle_put_reseller(self, username, body):
        resellers = read_resellers()
        idx = next((i for i, r in enumerate(resellers) if r["username"] == username), -1)
        if idx == -1:
            return self.send_json(404, {"error": "Reseller not found"})

        r = resellers[idx]
        if "password" in body and body["password"]:
            r["password"] = body["password"]
        if "days" in body:
            r["expire_date"] = calculate_expire_date(int(body["days"]))
        if "max_users" in body:
            if int(body["max_users"]) < 1:
                return self.send_json(400, {"error": "Max accounts must be at least 1"})
            r["max_users"] = int(body["max_users"])
        if "max_conn" in body:
            mc = int(body["max_conn"] or 0)
            if mc < 0 or mc > 1000:
                return self.send_json(400, {"error": "Max connections per account must be 0-1000 (0 = no limit)"})
            r["max_conn"] = mc
        if "protos" in body and r["rtype"] == "v2ray":
            protos = norm_protos(body["protos"])
            if not protos:
                return self.send_json(400, {"error": "Choose at least one V2Ray protocol"})
            r["protos"] = protos

        resellers[idx] = r
        write_resellers(resellers)
        self.send_json(200, dict(r, type=r["rtype"]))

    def handle_toggle_reseller(self, username):
        resellers = read_resellers()
        idx = next((i for i, r in enumerate(resellers) if r["username"] == username), -1)
        if idx == -1:
            return self.send_json(404, {"error": "Reseller not found"})

        resellers[idx]["enabled"] = not resellers[idx]["enabled"]
        write_resellers(resellers)
        self.send_json(200, {"success": True, "enabled": resellers[idx]["enabled"]})

    def handle_delete_reseller(self, username, delete_users=False):
        resellers = read_resellers()
        idx = next((i for i, r in enumerate(resellers) if r["username"] == username), -1)
        if idx == -1:
            return self.send_json(404, {"error": "Reseller not found"})

        if delete_users and resellers[idx]["rtype"] == "v2ray":
            for n in v2_owned_names(username):
                v2_cli(["del", n])
        elif delete_users:
            users = read_db()
            owned = [u for u in users if u.get("owner") == username]
            for u in owned:
                un = u["username"]
                force_delete_system_user(un)
                run_cmd(f"rm -f {BW_DIR}/{un}.*", ignore_errors=True)
                run_cmd(f"rm -f {BANNER_DIR}/{un}.txt", ignore_errors=True)
            
            with db_lock:
                if os.path.exists(DB_FILE):
                    with open(DB_FILE, "r") as f:
                        lines = f.readlines()
                    owned_names = set(u["username"] for u in owned)
                    with open(DB_FILE, "w") as f:
                        for line in lines:
                            parts = line.strip().split(":")
                            if parts and parts[0] not in owned_names:
                                f.write(line)

        del resellers[idx]
        write_resellers(resellers)

        # Invalidate reseller's sessions
        tokens_to_remove = [t for t, s in sessions.items() if s.get("username") == username and s.get("role") == "reseller"]
        for t in tokens_to_remove:
            del sessions[t]
        if tokens_to_remove:
            save_sessions()

        self.send_json(200, {"success": True})

    # ================= V2RAY (XRAY) =================
    def _v2_actor(self, session):
        """('admin', None) or ('reseller', record). Sends an error and returns None when not allowed."""
        if session.get("role") == "admin":
            return ("admin", None)
        r = get_reseller(session)
        if not r:
            self.send_json(403, {"error": "Reseller account not found"})
            return None
        bad = reseller_problem(r)
        if bad:
            self.send_json(403, {"error": bad})
            return None
        if r["rtype"] != "v2ray":
            self.send_json(403, {"error": "Your reseller account can only manage SSH accounts"})
            return None
        return ("reseller", r)

    @staticmethod
    def _v2_owns(actor, users, name):
        u = users.get(name)
        if not u:
            return False
        return actor[0] == "admin" or u.get("owner", "admin") == actor[1]["username"]

    def _v2_ready(self):
        if not v2_installed():
            self.send_json(409, {"error": "V2Ray is not installed. Install it from the menu (option 22) first."})
            return None
        try:
            mod = v2_module()
        except Exception as e:
            self.send_json(500, {"error": "Cannot load the V2Ray manager: %s" % e})
            return None
        if mod is None or getattr(mod, "FFV2RAY_API", 1) < 2:
            self.send_json(409, {"error": "The V2Ray manager is outdated (no device limit support). "
                                          "Update it from the menu: V2Ray > Update, then restart the panel."})
            return None
        return mod

    def _v2_detail(self, mod, name):
        st, users, usage = mod.load_settings(), mod.load_users(), mod.load_usage()
        u = users.get(name)
        if not u:
            return None
        p = mod.PROTOS[u["proto"]]
        fields = [["Remarks", name], ["Domain", st["domain"]], ["Port TLS", st["tls_port"]],
                  ["Port none TLS", st["http_port"]], ["Port GRPC", st["tls_port"]],
                  ["Password" if u["proto"] == "trojan" else "ID", u["id"]]]
        if u["proto"] == "vless":
            fields.append(["Encryption", "none"])
        elif u["proto"] == "vmess":
            fields += [["AlterId", "0"], ["Security", "auto"]]
        fields += [["Network", "ws"], ["Path", p["path"]], ["ServiceName", p["grpc"]]]
        cl = mod.user_conn_limit(u)
        fields.append(["Devices", str(cl) if cl > 0 else "Unlimited"])
        return {"user": v2_summary(mod, name, u, usage, int(time.time())), "fields": fields,
                "links": [{"label": l, "link": k} for l, k in mod.build_links(st, name, u)]}

    def handle_v2_get(self, api_path, qs, actor):
        parts = api_path.strip("/").split("/")          # api / v2ray / <sub> / [name]
        sub = parts[2] if len(parts) > 2 else ""
        is_admin = actor[0] == "admin"
        if sub == "status" and not v2_installed():
            return self.send_json(200, {"installed": False})
        mod = self._v2_ready()
        if mod is None:
            return
        try:
            all_users = mod.load_users()
            mine = {n: u for n, u in all_users.items() if self._v2_owns(actor, all_users, n)}
            if sub == "status":
                st = mod.load_settings()
                counts = {p: 0 for p in V2_PROTOS}
                for u in mine.values():
                    counts[u.get("proto")] = counts.get(u.get("proto"), 0) + 1
                active = lambda n: run_cmd(["systemctl", "is-active", n], ignore_errors=True)[0] == 0
                data = {
                    "installed": True, "domain": st.get("domain", ""), "tls_port": st.get("tls_port"),
                    "http_port": st.get("http_port"), "counts": counts, "total": len(mine),
                    "xray_running": active(mod.XRAY_SERVICE), "nginx_running": active(mod.NGINX_SERVICE),
                    "limiter_running": active(V2_LIMITER_SERVICE),
                    "is_admin": is_admin,
                    "allowed_protos": list(V2_PROTOS) if is_admin else reseller_protos(actor[1])}
                if not is_admin:
                    data["max_users"] = actor[1]["max_users"]
                    data["max_conn"] = actor[1].get("max_conn", 0)
                    data["created"] = len(mine)
                return self.send_json(200, data)
            if sub == "users" and len(parts) == 3:
                proto = (qs.get("proto", [""])[0] or "").lower()
                usage, now = mod.load_usage(), int(time.time())
                order = {p: i for i, p in enumerate(V2_PROTOS)}
                names = sorted(mine, key=lambda n: (order.get(mine[n].get("proto"), 9), n))
                if proto in V2_PROTOS:
                    names = [n for n in names if mine[n].get("proto") == proto]
                return self.send_json(200, {"users": [v2_summary(mod, n, mine[n], usage, now) for n in names]})
            if sub == "users" and len(parts) == 4:
                if not V2_NAME_RE.match(parts[3]):
                    return self.send_json(400, {"error": "Invalid account name"})
                if parts[3] not in mine:
                    return self.send_json(404, {"error": "Account not found"})
                d = self._v2_detail(mod, parts[3])
                return self.send_json(200, d) if d else self.send_json(404, {"error": "Account not found"})
            if sub == "online":
                om = v2_online_map()
                return self.send_json(200, {"online": {n: v for n, v in om.items() if n in mine}})
            return self.send_json(404, {"error": "Not Found"})
        except Exception as e:
            print("V2Ray GET error: %s" % e, file=sys.stderr)
            return self.send_json(500, {"error": str(e)})

    def _v2_run(self, args, mod, name=None):
        code, out, err = v2_cli(args)
        if code != 0:
            msg = (err or out or "Manager command failed").replace("Error: ", "").strip()
            return self.send_json(400, {"error": msg})
        d = self._v2_detail(mod, name) if name else None
        return self.send_json(200, dict(d or {}, success=True))

    def _v2_check_sell(self, mod, actor, proto):
        """Reseller rules for a NEW account: protocol allowed + quota left. True when fine."""
        if actor[0] == "admin":
            return True
        r = actor[1]
        if proto not in reseller_protos(r):
            self.send_json(403, {"error": "You are not allowed to sell %s accounts" % proto.upper()})
            return False
        owned = len(v2_owned_names(r["username"], mod.load_users()))
        if owned >= r["max_users"]:
            self.send_json(403, {"error": "Account limit reached (%d)" % r["max_users"]})
            return False
        return True

    def _v2_conn_ok(self, actor, conn):
        """Reseller per-account connection cap for V2Ray (0/unlimited is refused when a cap is set)."""
        if actor[0] == "admin":
            return True
        err = reseller_conn_error(actor[1], conn)
        if err:
            self.send_json(403, {"error": err})
            return False
        return True

    def handle_v2_post(self, path, body, actor):
        mod = self._v2_ready()
        if mod is None:
            return
        owner = "admin" if actor[0] == "admin" else actor[1]["username"]
        parts = path.strip("/").split("/")
        sub = parts[2] if len(parts) > 2 else ""
        try:
            if path == "/api/v2ray/users":                       # create
                proto = str(body.get("proto", "")).lower()
                name = str(body.get("name", "")).strip()
                if proto not in V2_PROTOS:
                    return self.send_json(400, {"error": "Choose VMess, VLess or Trojan"})
                if not V2_NAME_RE.match(name):
                    return self.send_json(400, {"error": "Name: 2-24 letters, digits, _ or -"})
                if not self._v2_check_sell(mod, actor, proto):
                    return
                days = v2_num(body.get("days"), 30, 1, 3650)
                conn = int(v2_num(body.get("conn_limit"), 1, 0, 1000))
                if not self._v2_conn_ok(actor, conn):
                    return
                return self._v2_run(["add", "--proto", proto, "--name", name, "--days", v2_fmt(days),
                                     "--total", v2_fmt(v2_num(body.get("total_gb"))),
                                     "--daily", v2_fmt(v2_num(body.get("daily_gb"))),
                                     "--conn", str(conn), "--owner", owner], mod, name)
            if path == "/api/v2ray/trial":                       # trial
                proto = str(body.get("proto", "")).lower()
                if proto not in V2_PROTOS:
                    return self.send_json(400, {"error": "Choose VMess, VLess or Trojan"})
                if not self._v2_check_sell(mod, actor, proto):
                    return
                name = str(body.get("name", "")).strip()
                if not name:
                    import random
                    users = mod.load_users()
                    while True:
                        name = "trial%04d" % random.randint(0, 9999)
                        if name not in users:
                            break
                if not V2_NAME_RE.match(name):
                    return self.send_json(400, {"error": "Name: 2-24 letters, digits, _ or -"})
                hours = v2_num(body.get("hours"), 1, 1, 720)
                conn = int(v2_num(body.get("conn_limit"), 1, 0, 1000))
                if not self._v2_conn_ok(actor, conn):
                    return
                return self._v2_run(["add", "--proto", proto, "--name", name, "--hours", v2_fmt(hours),
                                     "--total", v2_fmt(v2_num(body.get("total_gb"))), "--trial",
                                     "--conn", str(conn), "--owner", owner], mod, name)
            if path == "/api/v2ray/cleanup":
                if actor[0] != "admin":
                    return self.send_json(403, {"error": "Admin access required"})
                code, out, err = v2_cli(["cleanup"])
                return self.send_json(200 if code == 0 else 400, {"success": code == 0, "message": out or err})
            if sub == "users" and len(parts) == 5:
                name, action = parts[3], parts[4]
                if not V2_NAME_RE.match(name):
                    return self.send_json(400, {"error": "Invalid account name"})
                if not self._v2_owns(actor, mod.load_users(), name):
                    return self.send_json(404, {"error": "Account not found"})
                if action in ("lock", "unlock"):
                    return self._v2_run([action, name], mod, name)
                if action == "renew":
                    days = v2_num(body.get("days"), 30, 1, 3650)
                    args = ["renew", name, "--days", v2_fmt(days)]
                    if body.get("reset"):
                        args.append("--reset")
                    return self._v2_run(args, mod, name)
                if action == "limit":
                    args = ["limit", name, "--total", v2_fmt(v2_num(body.get("total_gb"))),
                            "--daily", v2_fmt(v2_num(body.get("daily_gb")))]
                    if "conn_limit" in body:
                        new_conn = int(v2_num(body.get("conn_limit"), 1, 0, 1000))
                        if not self._v2_conn_ok(actor, new_conn):
                            return
                        args += ["--conn", str(new_conn)]
                    if body.get("reset"):
                        args.append("--reset")
                    return self._v2_run(args, mod, name)
            return self.send_json(404, {"error": "Not Found"})
        except Exception as e:
            print("V2Ray POST error: %s" % e, file=sys.stderr)
            return self.send_json(500, {"error": str(e)})

    def handle_v2_delete(self, path, actor):
        mod = self._v2_ready()
        if mod is None:
            return
        parts = path.strip("/").split("/")
        if len(parts) == 4 and parts[2] == "users" and V2_NAME_RE.match(parts[3]):
            if not self._v2_owns(actor, mod.load_users(), parts[3]):
                return self.send_json(404, {"error": "Account not found"})
            return self._v2_run(["del", parts[3]], mod)
        return self.send_json(404, {"error": "Not Found"})


def main():
    os.makedirs(os.path.dirname(DB_FILE), exist_ok=True)
    server_address = ('0.0.0.0', PORT)
    httpd = ThreadingHTTPServer(server_address, PanelAPIHandler)
    print(f"Starting server on port {PORT} (data dir {DB_DIR}, html {PANEL_HTML}, html exists: {os.path.exists(PANEL_HTML)}, conf exists: {os.path.exists(PANEL_CONF)})", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    print("Server stopped.")

if __name__ == '__main__':
    main()
