#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
import shutil
import secrets
import hashlib
import threading
import re
import shlex
import socket
import base64
import hmac
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from http import cookies
from urllib.parse import urlparse, parse_qs, quote
from datetime import datetime, timedelta
from html import escape as html_escape

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
# First-run login + secret path. They live only here (server side) and are never sent to the browser
# or written into index.html. Used ONLY when no panel login exists yet; an existing panel.conf is never touched.
DEFAULT_ADMIN_USER = "visible"
DEFAULT_ADMIN_PASS = "zombie"
DEFAULT_PANEL_SECRET = "panel_vy4au6zu"
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
    {"name": "HAProxy (Port Multiplexer)", "service": "visibleTech-mux", "check_file": "/etc/systemd/system/visibleTech-mux.service",
     "port": "80/443", "port_confs": [("mux/mux.conf", "MUX_PLAIN_PORTS"), ("mux/mux.conf", "MUX_TLS_PORTS")]},
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

GB_BYTES = 1073741824

def set_system_password(user, pwd):
    """Set a Linux password through stdin (no shell, so quotes / $ / spaces in passwords are safe)."""
    try:
        r = subprocess.run(["chpasswd"], input=f"{user}:{pwd}\n", capture_output=True, text=True, timeout=10)
        if r.returncode != 0:
            print(f"chpasswd error for {user}: {r.stderr}", file=sys.stderr)
        return r.returncode == 0
    except Exception as e:
        print(f"chpasswd exception for {user}: {e}", file=sys.stderr)
        return False

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
    f = round(float(v), 4)          # panel/menu keep at most 4 decimals
    if f == int(f):
        return str(int(f))
    return ("%.4f" % f).rstrip("0").rstrip(".")   # never scientific notation (1e-05)

def format_db_line(u):
    bw = _fmt_bw(u.get('bandwidth_gb', 0))
    dbw = _fmt_bw(u.get('daily_bandwidth_gb', 0))
    owner = u.get('owner', 'admin')
    return f"{u['username']}:{u['password']}:{u['expire_date']}:{u['conn_limit']}:{bw}:{dbw}:{u.get('account_type','web')}:{owner}\n"

# --- RESELLERS DB ---
# line: username:password:expire_date:max_users:enabled[:type[:protocols[:max_conn[:slowdns]]]]
#   max_conn  = highest connection/device limit this reseller may give to ONE account (0 = no cap)
#   slowdns   = 1 when this V2Ray reseller may generate SlowDNS V2Ray configs (0/missing = no)
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
        "max_conn": int(parts[7]) if len(parts) > 7 and parts[7].strip().isdigit() else 0,
        "slowdns": rtype == "v2ray" and len(parts) > 8 and parts[8].strip() == "1"
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
    sd = "1" if (rtype == "v2ray" and r.get("slowdns")) else "0"
    return f"{r['username']}:{r['password']}:{r['expire_date']}:{r['max_users']}:{enabled}:{rtype}:{protos}:{int(r.get('max_conn', 0) or 0)}:{sd}\n"

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

# --- RESELLER RENAME: move every account he created to the new name -------------------------
_v2_owner_lock = threading.Lock()

def reassign_owner(old, new):
    """Change the owner label from `old` to `new` on SSH accounts (users.db) and V2Ray accounts.
    Returns (ssh_count, v2ray_count)."""
    n_ssh = n_v2 = 0
    with db_lock:
        if os.path.exists(DB_FILE):
            with open(DB_FILE, "r") as f:
                lines = f.readlines()
            out = []
            for line in lines:
                parts = line.rstrip("\n").split(":")
                if len(parts) > 7 and parts[7] == old and not line.lstrip().startswith("#"):
                    parts[7] = new
                    out.append(":".join(parts) + "\n")
                    n_ssh += 1
                else:
                    out.append(line)
            if n_ssh:
                tmp = DB_FILE + ".tmp"
                with open(tmp, "w") as f:
                    f.writelines(out)
                try:
                    shutil.copymode(DB_FILE, tmp)
                except OSError:
                    pass
                os.replace(tmp, DB_FILE)
    try:
        if v2_installed():
            mod = v2_module()
            if mod:
                import fcntl
                with _v2_owner_lock:
                    os.makedirs(V2_DATA_DIR, exist_ok=True)
                    with open(os.path.join(V2_DATA_DIR, ".lock"), "a+") as lk:
                        fcntl.flock(lk, fcntl.LOCK_EX)
                        try:
                            users = mod.load_users()
                            for u in users.values():
                                if u.get("owner", "admin") == old:
                                    u["owner"] = new
                                    n_v2 += 1
                            if n_v2:
                                mod.save_users(users)
                        finally:
                            fcntl.flock(lk, fcntl.LOCK_UN)
    except Exception as e:
        print("V2Ray owner re-assign error: %s" % e, file=sys.stderr)
        raise
    return n_ssh, n_v2


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

def v2_usage_by_owner():
    """{owner: [accounts, total_used_bytes, daily_used_bytes]} for all V2Ray accounts."""
    out = {}
    try:
        if not v2_installed():
            return out
        mod = v2_module()
        users, usage = mod.load_users(), mod.load_usage().get("users", {})
        for n, u in users.items():
            usg = usage.get(n, {})
            a = out.setdefault(u.get("owner") or "admin", [0, 0, 0])
            a[0] += 1
            a[1] += int(usg.get("total", 0))
            a[2] += int(usg.get("daily", 0))
    except Exception as e:
        print(f"V2Ray usage totals error: {e}", file=sys.stderr)
    return out

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

def ssh_usage_of(username):
    """(total_used_bytes, daily_used_bytes) of one SSH account, from the limiter counters."""
    return (read_file_int(f"{BW_DIR}/{username}.usage"), read_file_int(f"{BW_DIR}/{username}.daily_usage"))

def ssh_usage_by_owner(users):
    """{owner: [accounts, total_used_bytes, daily_used_bytes]} for a list of users.db entries."""
    out = {}
    for u in users:
        t, d = ssh_usage_of(u["username"])
        a = out.setdefault(u.get("owner") or "admin", [0, 0, 0])
        a[0] += 1; a[1] += t; a[2] += d
    return out

def rename_ssh_user_files(old, new):
    """Move every per-user file (bandwidth counters, locks, banner, admin message) to the new name."""
    try:
        if os.path.isdir(BW_DIR):
            for fn in os.listdir(BW_DIR):
                p = os.path.join(BW_DIR, fn)
                if fn.startswith(old + ".") and os.path.isfile(p):
                    os.replace(p, os.path.join(BW_DIR, new + fn[len(old):]))
            pid_dir = os.path.join(BW_DIR, "pidtrack")
            if os.path.isdir(pid_dir):
                for fn in os.listdir(pid_dir):
                    if fn.startswith(old + "__"):
                        try:
                            os.remove(os.path.join(pid_dir, fn))
                        except OSError:
                            pass
        for d in (BANNER_DIR, V2_ADMIN_MSG_DIR):
            p = os.path.join(d, old + ".txt")
            if os.path.isfile(p):
                os.replace(p, os.path.join(d, new + ".txt"))
    except Exception as e:
        print(f"rename files error {old}->{new}: {e}", file=sys.stderr)

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
    creds = {"PANEL_USER": "", "PANEL_PASS_HASH": "", "PANEL_PASS_PLAIN": "", "PANEL_SECRET": "", "PANEL_NAME": DEFAULT_PANEL_NAME, "PANEL_LOGO": DEFAULT_PANEL_LOGO, "PANEL_DOMAIN": ""}
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

def write_panel_creds(user, pass_plain, secret=None, panel_name=None, panel_logo=None, panel_domain=None):
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
    if panel_domain is not None:
        creds["PANEL_DOMAIN"] = panel_domain
    
    os.makedirs(os.path.dirname(PANEL_CONF), exist_ok=True)
    with open(PANEL_CONF, "w") as f:
        for k, v in creds.items():
            f.write(f"{k}={v}\n")

# --- PANEL DOMAIN (shared with V2Ray / SSH WS / Stunnel) ---
PANEL_DOMAIN_RE = re.compile(r'^[a-z0-9]([a-z0-9.-]{0,251}[a-z0-9])?$')
IPV4_RE = re.compile(r'^\d{1,3}(\.\d{1,3}){3}$')

def clean_panel_domain(value):
    """Normalise a typed domain ('' = clear). Raises ValueError when it is not a real domain name."""
    v = str(value or "").strip().lower()
    for pre in ("https://", "http://"):
        if v.startswith(pre):
            v = v[len(pre):]
    v = v.split("/", 1)[0].split(":", 1)[0].strip()
    if not v:
        return ""
    if "." not in v or IPV4_RE.match(v) or not PANEL_DOMAIN_RE.match(v) or ".." in v:
        raise ValueError("Invalid domain name (use something like vpn.example.com, not an IP)")
    return v

def detected_server_domains():
    """Domains already configured on this server: [{domain, source}] without duplicates."""
    found = []
    def add(d, src):
        try:
            d = clean_panel_domain(d)
        except ValueError:
            return
        if not d:
            return
        for f in found:
            if f["domain"] == d:
                if src not in f["source"]:
                    f["source"] += " + " + src
                return
        found.append({"domain": d, "source": src})
    try:
        with open(os.path.join(V2_DATA_DIR, "settings.json"), "r") as f:
            add(json.load(f).get("domain", ""), "V2Ray")
    except Exception:
        pass
    add(conf_value("stunnel_info.conf", "ST_CERT_DOMAIN"), "SSH WS/Stunnel")
    add(conf_value("dns_info.conf", "FULL_DOMAIN"), "SSH WS/Stunnel")
    return found

def seed_default_creds():
    """Fresh install only: create the default admin login and secret path when panel.conf has no login."""
    try:
        c = get_panel_creds()
        if c.get("PANEL_USER") and c.get("PANEL_PASS_HASH"):
            return False
        write_panel_creds(DEFAULT_ADMIN_USER, DEFAULT_ADMIN_PASS,
                          secret=(c.get("PANEL_SECRET") or DEFAULT_PANEL_SECRET))
        try:
            os.chmod(PANEL_CONF, 0o600)
        except OSError:
            pass
        print("No panel login found: default admin login and secret path created.", flush=True)
        return True
    except Exception as e:
        print(f"Could not create default panel login: {e}", file=sys.stderr, flush=True)
        return False

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

V2_SETEXP_CODE = r"""
import sys, importlib.util
spec = importlib.util.spec_from_file_location('ffv2ray_manager', sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
name, ts = sys.argv[2], int(sys.argv[3])
m.need_installed()
with m.locked():
    users = m.load_users()
    if name not in users:
        sys.stderr.write('Error: account not found\n')
        sys.exit(1)
    users[name]['expiry'] = ts
    m.save_users(users)
    m.apply_all()
print('OK')
"""


def v2_set_expiry(name, ts, timeout=90):
    env = dict(os.environ, FFV2_DIR=V2_DATA_DIR, NO_COLOR="1")
    try:
        p = subprocess.run([sys.executable, "-c", V2_SETEXP_CODE, V2_MANAGER, name, str(int(ts))],
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env,
                           timeout=timeout, universal_newlines=True)
        return p.returncode, _ANSI_RE.sub("", p.stdout or "").strip(), _ANSI_RE.sub("", p.stderr or "").strip()
    except Exception as e:
        return -1, "", str(e)


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


# --- SLOWDNS V2RAY ------------------------------------------------------------------------
# DNSTT (FastDns) can forward its tunnel to an Xray WebSocket inbound instead of SSH. The menu
# does the server side (DNSTT menu > Set forwarding target); the panel manages the tunnels,
# stores the default NS / resolver and builds the client config (HTTP Custom style) per account.
SLOWDNS_FILE = V2_DATA_DIR + "/slowdns.json"
FASTDNS_DIR = "/etc/fastdns"
FASTDNS_MAIN_UNIT = "/etc/systemd/system/server-sldns.service"
FASTDNS_TUNNELS = FASTDNS_DIR + "/tunnels.conf"
FASTDNS_PUB = FASTDNS_DIR + "/server.pub"
FASTDNS_MODED = "/usr/local/lib/visibleTech-fastdns/moded.sh"
SLOWDNS_PORTS = {"vmess": 10001, "vless": 10002, "trojan": 10003}      # Xray WS inbounds on 127.0.0.1
SLOWDNS_PATHS = {"vmess": "/vmess", "vless": "/vless", "trojan": "/trojan-ws"}
SLOWDNS_DOMAIN_RE = re.compile(r'^[a-z0-9]([a-z0-9.-]{0,251}[a-z0-9])?$')

def slowdns_allowed(actor):
    """Admin always; a reseller only when the admin switched SlowDNS access on for him."""
    return actor[0] == "admin" or bool(actor[1].get("slowdns"))

def slowdns_load():
    d = {"ns": "", "resolver": "", "resolver_name": "", "port": 10109}
    try:
        with open(SLOWDNS_FILE) as f:
            saved = json.load(f)
        if isinstance(saved, dict):
            for k in d:
                if k in saved:
                    d[k] = saved[k]
    except (OSError, ValueError):
        pass
    return d

def slowdns_save(d):
    os.makedirs(V2_DATA_DIR, exist_ok=True)
    tmp = SLOWDNS_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(d, f, indent=2)
    os.chmod(tmp, 0o600)
    os.replace(tmp, SLOWDNS_FILE)

def slowdns_norm_ns(v):
    v = str(v or "").strip().lower().rstrip(".")
    if not v:
        return ""
    if "." not in v or not SLOWDNS_DOMAIN_RE.match(v):
        raise ValueError("Invalid NS domain")
    return v

def slowdns_norm_port(v, default=10109):
    if v in (None, ""):
        return default
    try:
        p = int(v)
    except (TypeError, ValueError):
        raise ValueError("Port must be a number")
    if p < 1 or p > 65535:
        raise ValueError("Port must be 1-65535")
    return p

def slowdns_resolve(v):
    """DNS resolver given as an IPv4 address or a hostname -> IPv4 address ('' = none)."""
    v = str(v or "").strip()
    if not v:
        return ""
    if re.match(r'^\d{1,3}(\.\d{1,3}){3}$', v):
        if all(int(x) <= 255 for x in v.split(".")):
            return v
        raise ValueError("Invalid resolver IP")
    if not re.match(r'^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$', v):
        raise ValueError("Invalid resolver")
    try:
        return socket.gethostbyname(v)
    except OSError:
        raise ValueError("Could not resolve %s - enter its IP address instead" % v)

def slowdns_pubkey():
    try:
        with open(FASTDNS_PUB) as f:
            return f.readline().strip()
    except OSError:
        return ""

def slowdns_target_name(port):
    for n, pt in SLOWDNS_PORTS.items():
        if pt == port:
            return n
    return "ssh" if port else "unknown"

def slowdns_tunnels(check_running=False):
    """Main + extra FastDns tunnels: [{domain, main, service, forward_port, target[, running]}]."""
    out = []

    def add(unit_file, svc, main):
        ex = ""
        try:
            with open(unit_file) as f:
                for line in f:
                    if line.startswith("ExecStart="):
                        ex = line.strip()
                        break
        except OSError:
            return
        m = re.search(r'-privkey-file \S+ (\S+) 127\.0\.0\.1:(\d+)\s*$', ex)
        if not m:
            return
        fp = int(m.group(2))
        t = {"domain": m.group(1).lower(), "main": main, "service": svc,
             "forward_port": fp, "target": slowdns_target_name(fp)}
        if check_running:
            t["running"] = run_cmd(["systemctl", "is-active", svc], ignore_errors=True)[0] == 0
        out.append(t)

    add(FASTDNS_MAIN_UNIT, "server-sldns", True)
    try:
        with open(FASTDNS_TUNNELS) as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 2 and parts[1].isdigit():
                    svc = "server-sldns-" + parts[1]
                    add("/etc/systemd/system/%s.service" % svc, svc, False)
    except OSError:
        pass
    return out

def slowdns_warning(ns, proto, is_admin):
    """Why this NS would not reach the account's V2Ray protocol ('' = fine)."""
    tunnels = slowdns_tunnels()
    if not tunnels:
        return "FastDns (DNSTT) is not installed on this server."
    for t in tunnels:
        if t["domain"] == ns:
            if t["forward_port"] != SLOWDNS_PORTS.get(proto):
                fix = "Switch it in V2Ray > SlowDNS." if is_admin else "Ask the admin to switch it."
                return "%s currently forwards to %s, not to %s. %s" % (ns, t["target"].upper(), proto.upper(), fix)
            return ""
    return "%s is not one of this server's SlowDNS tunnel domains." % ns

def slowdns_build_config(proto, ident, ns, resolver, port):
    """Flat SlowDNS V2Ray config: raw TCP outbound to the app's local SlowDNS port, then the
    slowdns fields (NS, resolver) at the top level. Always serialises to valid JSON."""
    if proto == "vless":
        settings = {"vnext": [{"address": "127.0.0.1", "port": port,
                               "users": [{"encryption": "none", "id": ident, "level": 8}]}]}
    elif proto == "vmess":
        settings = {"vnext": [{"address": "127.0.0.1", "port": port,
                               "users": [{"id": ident, "alterId": 0, "security": "auto", "level": 8}]}]}
    else:
        settings = {"servers": [{"address": "127.0.0.1", "port": port, "password": ident, "level": 8}]}
    return {
        "inbounds": [],
        "outbounds": [{
            "mux": {"enabled": False},
            "protocol": proto,
            "settings": settings,
            "streamSettings": {"network": "tcp"},
            "tag": proto.upper()
        }],
        "policy": {"levels": {"8": {"connIdle": 300, "downlinkOnly": 1, "handshake": 4, "uplinkOnly": 1}}},
        "version": "645",
        "slowdnsEnabled": "true",
        "slowdnsServer": ns,
        "dnsResolver": resolver,
        "protections": {}
    }


# --- V2RAY SUBSCRIPTION (live "banner": info lines + usage headers, refreshed by the client app) ---
V2_SUB_KEY_FILE = os.path.join(V2_DATA_DIR, "sub.key")
V2_ADMIN_MSG_DIR = DB_DIR + "/admin_messages"
V2_ADMIN_MSG_GLOBAL = DB_DIR + "/admin_message_global.txt"
V2_SUB_RE = re.compile(r'^/sub/([A-Za-z0-9_-]{2,24})/([0-9a-f]{32})$')
_V2_GB = 1073741824.0

def v2_sub_secret():
    """Random server-side key (created once) used to sign per-account subscription tokens."""
    try:
        with open(V2_SUB_KEY_FILE, "r") as f:
            k = f.read().strip()
            if len(k) >= 32:
                return k
    except OSError:
        pass
    k = secrets.token_hex(24)
    os.makedirs(os.path.dirname(V2_SUB_KEY_FILE), exist_ok=True)
    fd = os.open(V2_SUB_KEY_FILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(k)
    return k

def v2_sub_token(name, u):
    msg = ("%s:%s" % (name, u.get("id", ""))).encode()
    return hmac.new(v2_sub_secret().encode(), msg, hashlib.sha256).hexdigest()[:32]

def v2_retitle(link, title):
    """Replace the profile name (remark) of a vmess/vless/trojan share link."""
    if link.startswith("vmess://"):
        try:
            b = link[8:]
            obj = json.loads(base64.b64decode(b + "=" * (-len(b) % 4)).decode("utf-8"))
            obj["ps"] = title
            raw = json.dumps(obj, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
            return "vmess://" + base64.b64encode(raw).decode()
        except Exception:
            return link
    return link.split("#", 1)[0] + "#" + quote(title, safe="")

def v2_info_link(title):
    """Non-working placeholder profile whose NAME carries a line of account info (shows as a banner row)."""
    return ("vless://00000000-0000-0000-0000-000000000000@127.0.0.1:1"
            "?encryption=none&type=tcp#" + quote(title, safe=""))

def v2_read_admin_msg(name):
    for p in ("%s/%s.txt" % (V2_ADMIN_MSG_DIR, name), V2_ADMIN_MSG_GLOBAL):
        try:
            if os.path.isfile(p) and os.path.getsize(p) > 0:
                with open(p, "r", encoding="utf-8", errors="ignore") as f:
                    t = f.read(600).replace("\r", " ").replace("\n", " ").strip()
                if t:
                    return t
        except OSError:
            pass
    return ""

def v2_build_subscription(mod, name, u, with_info=True):
    """Returns (headers, body_bytes) for one account."""
    st, usage = mod.load_settings(), mod.load_usage()
    now = int(time.time())
    usg = usage["users"].get(name, {})
    status = mod.user_status(u, usg, now)
    used, today = int(usg.get("total", 0)), int(usg.get("daily", 0))
    up, down = int(usg.get("up", 0)), int(usg.get("down", 0))
    tl = mod.quota_bytes(u.get("total_gb", 0))
    dl = mod.quota_bytes(u.get("daily_gb", 0))
    exp = int(u.get("expiry", 0) or 0)

    icon = {"active": "🟢", "locked": "🟡", "expired": "🔴", "quota": "🔴", "daily": "🟠"}.get(status, "⚪")
    stext = mod.STATUS_TEXT.get(status, (status,))[0]
    if exp:
        left = exp - now
        if left <= 0:
            exp_line = "📅 Expired %s" % time.strftime("%Y-%m-%d", time.localtime(exp))
        else:
            d, h = left // 86400, (left % 86400) // 3600
            exp_line = "📅 Expires %s • %s" % (time.strftime("%Y-%m-%d", time.localtime(exp)),
                                               ("%dd %dh left" % (d, h)) if d else ("%dh left" % h))
    else:
        exp_line = "📅 Never expires ∞"
    if tl > 0:
        pct = min(100, int(used * 100 / tl))
        filled = (pct * 10 + 50) // 100
        bar = "▰" * filled + "▱" * (10 - filled)
        total_line = "📊 %s %d%% • %.2f/%s GB" % (bar, pct, used / _V2_GB, v2_fmt(float(u.get("total_gb", 0))))
    else:
        total_line = "📊 Used %.2f GB • Unlimited" % (used / _V2_GB)
    info = ["%s %s • %s" % (icon, name, stext), exp_line, total_line]
    if dl > 0:
        info.append("📈 Today %.2f/%s GB" % (today / _V2_GB, v2_fmt(float(u.get("daily_gb", 0)))))
    cl = mod.user_conn_limit(u)
    if cl > 0:
        info.append("🖲️ Devices limit: %d" % cl)
    msg = v2_read_admin_msg(name)
    if msg:
        info.append("📢 " + msg)

    links = []
    if with_info:
        links += [v2_info_link(t) for t in info]
    if status == "active":
        short = {"Link TLS": "TLS", "Link none TLS": "NTLS", "Link GRPC": "gRPC"}
        build = getattr(mod, "_build_share_links", None)
        pairs = build(st, name, u) if build else [(l, k) for l, k in mod.build_links(st, name, u)
                                                  if l.startswith("Link")]
        for label, link in pairs:
            links.append(v2_retitle(link, "%s %s • %s" % (icon, name, short.get(label, label))))
    body = base64.b64encode("\n".join(links).encode("utf-8"))

    ui = ["upload=%d" % up, "download=%d" % down]
    if tl > 0:
        ui.append("total=%d" % tl)
    if exp:
        ui.append("expire=%d" % exp)
    headers = {
        "Content-Type": "text/plain; charset=utf-8",
        "Subscription-Userinfo": "; ".join(ui),
        "Profile-Title": "base64:" + base64.b64encode(("🦅 " + name).encode("utf-8")).decode(),
        "Profile-Update-Interval": "1",
        "Content-Disposition": 'attachment; filename="%s"' % name,
        "Cache-Control": "no-store",
        "announce": "base64:" + base64.b64encode(" | ".join(info).encode("utf-8")).decode(),
    }
    return headers, body


# --- V2RAY USAGE PAGE (public, token-protected link the client opens in a normal browser) ---
V2_USAGE_RE = re.compile(r'^/u/([A-Za-z0-9_-]{2,24})/([0-9a-f]{32})(/data)?$')
V2_PROTO_LABEL = {"vless": "VLESS", "vmess": "VMess", "trojan": "Trojan"}

V2_USAGE_PAGE = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="robots" content="noindex,nofollow">
<meta name="referrer" content="no-referrer">
<meta name="theme-color" content="#070b16">
<title>%%NAME%% • Usage</title>
<style>
:root{--bg:#070b16;--tx:#eaf0ff;--mut:#8b97b8;--card:rgba(255,255,255,.055);--bd:rgba(255,255,255,.11);--trk:rgba(255,255,255,.09);
--a:#22d3ee;--b:#818cf8;--ok:#34d399;--warn:#fbbf24;--bad:#fb7185;--sh:0 20px 60px rgba(0,0,0,.45);--blob1:#4f46e5;--blob2:#06b6d4;--blob3:#c026d3}
@media (prefers-color-scheme:light){:root{--bg:#eef2ff;--tx:#0f172a;--mut:#5b6785;--card:rgba(255,255,255,.72);--bd:rgba(15,23,42,.08);--trk:rgba(15,23,42,.09);--sh:0 20px 50px rgba(79,70,229,.14);--blob1:#a5b4fc;--blob2:#67e8f9;--blob3:#f0abfc}.proto{color:#0e7490}}
*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent}
html,body{min-height:100%}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;background:var(--bg);color:var(--tx);overflow-x:hidden;line-height:1.35}
.bg{position:fixed;inset:0;z-index:0;overflow:hidden;pointer-events:none}
.bg i{position:absolute;border-radius:50%;filter:blur(90px);opacity:.38;animation:fl 18s ease-in-out infinite alternate}
.bg i:nth-child(1){width:420px;height:420px;background:var(--blob1);top:-120px;left:-100px}
.bg i:nth-child(2){width:380px;height:380px;background:var(--blob2);bottom:-120px;right:-80px;animation-delay:-6s}
.bg i:nth-child(3){width:300px;height:300px;background:var(--blob3);top:45%;left:55%;opacity:.22;animation-delay:-12s}
@keyframes fl{to{transform:translate(60px,40px) scale(1.15)}}
.wrap{position:relative;z-index:1;max-width:560px;margin:0 auto;padding:max(22px,env(safe-area-inset-top)) 16px 40px}
.top{display:flex;align-items:center;gap:12px;margin-bottom:22px;animation:up .6s both}
.logo{width:46px;height:46px;border-radius:14px;background:linear-gradient(135deg,var(--a),var(--b));display:grid;place-items:center;font-size:24px;box-shadow:0 8px 24px rgba(99,102,241,.45);overflow:hidden;flex:none}
.logo img{width:100%;height:100%;object-fit:cover}
.brand{font-weight:700;font-size:17px;letter-spacing:.2px}
.brand small{display:block;font-weight:500;font-size:12px;color:var(--mut);margin-top:1px}
.pill{margin-left:auto;display:flex;align-items:center;gap:7px;padding:7px 13px;border-radius:99px;font-size:12.5px;font-weight:700;background:var(--card);border:1px solid var(--bd);backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);white-space:nowrap}
.pill b{width:8px;height:8px;border-radius:50%;background:var(--mut)}
.pill.ok{color:var(--ok)}.pill.ok b{background:var(--ok);box-shadow:0 0 0 0 var(--ok);animation:pu 2s infinite}
.pill.warn{color:var(--warn)}.pill.warn b{background:var(--warn)}
.pill.bad{color:var(--bad)}.pill.bad b{background:var(--bad)}
@keyframes pu{0%{box-shadow:0 0 0 0 rgba(52,211,153,.55)}70%{box-shadow:0 0 0 9px rgba(52,211,153,0)}100%{box-shadow:0 0 0 0 rgba(52,211,153,0)}}
.card{background:var(--card);border:1px solid var(--bd);border-radius:26px;backdrop-filter:blur(18px);-webkit-backdrop-filter:blur(18px);box-shadow:var(--sh);padding:22px;animation:up .7s both}
@keyframes up{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:none}}
.hello{font-size:13px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:1.4px}
.uname{font-size:28px;font-weight:800;margin:2px 0 4px;word-break:break-all;background:linear-gradient(90deg,var(--tx),var(--a));-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent}
.proto{display:inline-block;font-size:11.5px;font-weight:700;padding:3px 10px;border-radius:99px;background:linear-gradient(90deg,rgba(34,211,238,.18),rgba(129,140,248,.18));border:1px solid var(--bd);color:var(--a);letter-spacing:.5px}
.hero{display:flex;flex-direction:column;align-items:center;margin-top:18px}
.ring{position:relative;width:230px;height:230px}
.ring svg{width:100%;height:100%;transform:rotate(-90deg);overflow:visible}
.ring .trk{fill:none;stroke:var(--trk);stroke-width:15}
.ring .bar{fill:none;stroke:url(#g1);stroke-width:15;stroke-linecap:round;stroke-dasharray:578;stroke-dashoffset:578;transition:stroke-dashoffset 1.4s cubic-bezier(.2,.8,.2,1);filter:drop-shadow(0 0 10px rgba(34,211,238,.55))}
.ring.warn .bar{stroke:url(#g2);filter:drop-shadow(0 0 10px rgba(251,191,36,.55))}
.ring.bad .bar{stroke:url(#g3);filter:drop-shadow(0 0 10px rgba(251,113,133,.55))}
.ring.inf .bar{stroke-dasharray:3 13;stroke-dashoffset:0;animation:spin 22s linear infinite;transform-origin:center;transition:none}
@keyframes spin{to{transform:rotate(360deg)}}
.ctr{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center}
.pct{font-size:50px;font-weight:800;letter-spacing:-1.5px;line-height:1}
.pct sup{font-size:22px;font-weight:700;color:var(--mut);margin-left:2px;vertical-align:top;position:relative;top:6px}
.csub{font-size:12.5px;color:var(--mut);font-weight:600;margin-top:6px;text-transform:uppercase;letter-spacing:1.2px}
.line{margin-top:16px;text-align:center;font-size:15px;color:var(--mut)}
.line b{color:var(--tx);font-weight:700}
.rem{margin-top:6px;font-size:13px;color:var(--mut)}
.rem b{color:var(--ok)}
.notice{margin-top:16px;padding:12px 14px;border-radius:16px;font-size:13.5px;font-weight:600;display:none;border:1px solid var(--bd)}
.notice.show{display:block}
.notice.warn{background:rgba(251,191,36,.12);color:var(--warn)}
.notice.bad{background:rgba(251,113,133,.12);color:var(--bad)}
.msg{display:none;margin-top:14px;padding:13px 15px;border-radius:16px;font-size:13.5px;background:linear-gradient(90deg,rgba(34,211,238,.12),rgba(129,140,248,.12));border:1px solid var(--bd)}
.msg.show{display:flex;gap:10px;align-items:flex-start}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:14px}
.tile{background:var(--card);border:1px solid var(--bd);border-radius:20px;padding:15px 16px;backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);animation:up .8s both}
.tile:nth-child(2){animation-delay:.07s}.tile:nth-child(3){animation-delay:.14s}.tile:nth-child(4){animation-delay:.21s}
.ti{width:34px;height:34px;border-radius:11px;display:grid;place-items:center;font-size:17px;margin-bottom:10px;background:linear-gradient(135deg,rgba(34,211,238,.2),rgba(129,140,248,.2))}
.tl{font-size:12px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:1px}
.tv{font-size:21px;font-weight:800;margin-top:3px;letter-spacing:-.3px}
.tv small{font-size:12.5px;color:var(--mut);font-weight:600}
.mini{height:6px;border-radius:9px;background:var(--trk);margin-top:10px;overflow:hidden}
.mini i{display:block;height:100%;width:0;border-radius:9px;background:linear-gradient(90deg,var(--a),var(--b));transition:width 1.2s cubic-bezier(.2,.8,.2,1)}
.mini i.warn{background:linear-gradient(90deg,#fbbf24,#f97316)}.mini i.bad{background:linear-gradient(90deg,#fb7185,#e11d48)}
.exp{margin-top:14px;animation:up .9s both}
.exph{display:flex;justify-content:space-between;align-items:center;margin-bottom:14px}
.exph span{font-size:12px;color:var(--mut);font-weight:600;text-transform:uppercase;letter-spacing:1px}
.exph em{font-style:normal;font-size:13px;font-weight:700}
.cd{display:grid;grid-template-columns:repeat(4,1fr);gap:9px}
.cd div{text-align:center;padding:12px 4px;border-radius:16px;background:var(--trk)}
.cd b{display:block;font-size:26px;font-weight:800;font-variant-numeric:tabular-nums;line-height:1}
.cd small{display:block;font-size:11px;color:var(--mut);margin-top:5px;font-weight:600;text-transform:uppercase;letter-spacing:.8px}
.cd.inf div{display:none}.cd.inf .infb{display:block;grid-column:1/-1;font-size:19px;font-weight:800;padding:16px 10px}
.infb{display:none}
.foot{display:flex;align-items:center;justify-content:space-between;margin-top:20px;font-size:12.5px;color:var(--mut);animation:up 1s both}
.live{display:flex;align-items:center;gap:7px}
.live b{width:7px;height:7px;border-radius:50%;background:var(--ok);animation:pu 2s infinite}
.live.off b{background:var(--bad);animation:none}
button.rf{font:inherit;font-weight:700;font-size:12.5px;color:var(--tx);background:var(--card);border:1px solid var(--bd);border-radius:99px;padding:8px 15px;cursor:pointer;backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px)}
button.rf:active{transform:scale(.95)}
.copy{text-align:center;margin-top:18px;font-size:11.5px;color:var(--mut);opacity:.75}
.err{display:none;text-align:center;padding:40px 10px}
.err h2{font-size:22px;margin-bottom:8px}.err p{color:var(--mut);font-size:14px}
body.dead .main{display:none}body.dead .err{display:block}
@media (min-width:600px){.ring{width:250px;height:250px}.uname{font-size:32px}}
@media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
</style>
</head>
<body>
<div class="bg"><i></i><i></i><i></i></div>
<div class="wrap">
  <div class="top">
    <div class="logo">%%LOGO%%</div>
    <div class="brand">%%PANEL%%<small>Account usage</small></div>
    <div class="pill" id="pill"><b></b><span id="st">…</span></div>
  </div>

  <div class="err card"><h2>Account not available</h2><p>This link is no longer valid or the account was removed.<br>Please contact your provider.</p></div>

  <div class="main">
    <div class="card">
      <div class="hello">Welcome back</div>
      <div class="uname">%%NAME%%</div>
      <span class="proto" id="proto">—</span>

      <div class="hero">
        <div class="ring" id="ring">
          <svg viewBox="0 0 200 200">
            <defs>
              <linearGradient id="g1" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#22d3ee"/><stop offset="1" stop-color="#818cf8"/></linearGradient>
              <linearGradient id="g2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fbbf24"/><stop offset="1" stop-color="#f97316"/></linearGradient>
              <linearGradient id="g3" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fb7185"/><stop offset="1" stop-color="#e11d48"/></linearGradient>
            </defs>
            <circle class="trk" cx="100" cy="100" r="92"/>
            <circle class="bar" id="bar" cx="100" cy="100" r="92"/>
          </svg>
          <div class="ctr"><div class="pct" id="pct">0<sup>%</sup></div><div class="csub" id="csub">used</div></div>
        </div>
        <div class="line" id="line">&nbsp;</div>
        <div class="rem" id="rem"></div>
      </div>
      <div class="notice" id="notice"></div>
      <div class="msg" id="msg"><span>📢</span><span id="msgt"></span></div>
    </div>

    <div class="grid">
      <div class="tile"><div class="ti">📈</div><div class="tl">Today</div><div class="tv" id="today">0</div><div class="mini" id="tbar" style="display:none"><i></i></div></div>
      <div class="tile"><div class="ti">🖲️</div><div class="tl">Devices</div><div class="tv" id="dev">—</div></div>
      <div class="tile"><div class="ti">⬇️</div><div class="tl">Download</div><div class="tv" id="down">0</div></div>
      <div class="tile"><div class="ti">⬆️</div><div class="tl">Upload</div><div class="tv" id="up">0</div></div>
    </div>

    <div class="card exp">
      <div class="exph"><span>⏳ Time remaining</span><em id="edate">—</em></div>
      <div class="cd" id="cd">
        <div><b id="cd-d">0</b><small>Days</small></div>
        <div><b id="cd-h">0</b><small>Hours</small></div>
        <div><b id="cd-m">0</b><small>Min</small></div>
        <div><b id="cd-s">0</b><small>Sec</small></div>
        <div class="infb">∞ Never expires</div>
      </div>
      <div class="mini" id="vbar" style="display:none;margin-top:14px"><i></i></div>
    </div>

    <div class="foot">
      <div class="live" id="live"><b></b><span id="lt">Live</span></div>
      <button class="rf" id="rf" type="button">⟳ Refresh</button>
    </div>
  </div>
  <div class="copy">%%PANEL%% • Private link — don't share it with others</div>
</div>

<script>
(function(){
var $=function(i){return document.getElementById(i)};
var GB=1073741824,MB=1048576,C=578;
var D=null,off=0,lastOk=0,S={};
function fb(n){n=Math.max(0,n||0);if(n>=GB)return(n/GB).toFixed(2)+' GB';if(n>=MB)return(n/MB).toFixed(1)+' MB';if(n>=1024)return Math.round(n/1024)+' KB';return n+' B'}
function ease(t){return 1-Math.pow(1-t,3)}
function tween(key,to,fn,ms){
  var from=S[key]||0;S[key]=to;if(from===to){fn(to);return}
  var t0=performance.now();ms=ms||900;
  (function f(t){var p=Math.min(1,(t-t0)/ms);fn(from+(to-from)*ease(p));if(p<1)requestAnimationFrame(f)})(t0);
}
function cls(p){return p>=90?'bad':p>=70?'warn':''}
function render(d){
  D=d;off=d.now-Date.now()/1000;lastOk=Date.now();
  var st=d.status,k=st==='active'?'ok':(st==='locked'||st==='daily')?'warn':'bad';
  $('pill').className='pill '+k;$('st').textContent=d.status_text||st;
  $('proto').textContent=d.proto_label;
  var ring=$('ring'),bar=$('bar');
  if(d.total_bytes>0){
    var p=d.pct_total||0,c=cls(p);
    ring.className='ring '+c;
    bar.style.strokeDashoffset=C*(1-p/100);
    tween('pct',p,function(v){$('pct').innerHTML=Math.round(v)+'<sup>%</sup>'},1100);
    $('csub').textContent='used';
    $('line').innerHTML='<b>'+fb(d.used)+'</b> of <b>'+fb(d.total_bytes)+'</b>';
    var left=Math.max(0,d.total_bytes-d.used);
    $('rem').innerHTML='<b>'+fb(left)+'</b> remaining';
  }else{
    ring.className='ring inf';bar.style.strokeDashoffset=0;
    $('pct').innerHTML='∞';$('csub').textContent='Unlimited data';
    $('line').innerHTML='<b>'+fb(d.used)+'</b> used so far';$('rem').textContent='';
  }
  tween('today',d.today,function(v){$('today').innerHTML=fb(v)+(d.daily_bytes>0?' <small>/ '+fb(d.daily_bytes)+'</small>':'')});
  var tb=$('tbar');
  if(d.daily_bytes>0){var tp=Math.min(100,d.today*100/d.daily_bytes);tb.style.display='block';var i=tb.firstChild;i.className=cls(tp);i.style.width=tp+'%'}else tb.style.display='none';
  tween('down',d.down,function(v){$('down').textContent=fb(v)});
  tween('up',d.up,function(v){$('up').textContent=fb(v)});
  $('dev').innerHTML=d.conn_limit>0?d.conn_limit+' <small>max</small>':'Unlimited';
  $('edate').textContent=d.expiry?d.expiry_date:'Never';
  var vb=$('vbar');
  if(d.expiry&&d.created&&d.expiry>d.created){var tot=d.expiry-d.created,el=Math.min(tot,Math.max(0,d.now-d.created)),vp=el*100/tot;vb.style.display='block';var j=vb.firstChild;j.className=cls(vp);j.style.width=vp+'%'}else vb.style.display='none';
  var n=$('notice'),txt='';
  if(st==='expired')txt='Your account has expired. Please contact your provider to renew.';
  else if(st==='quota')txt='You have used all of your data. Please contact your provider to top up.';
  else if(st==='daily')txt='Daily data limit reached. It will reset automatically.';
  else if(st==='locked')txt='This account is temporarily locked. Please contact your provider.';
  else if(d.total_bytes>0&&d.pct_total>=90)txt='You are almost out of data.';
  else if(d.expiry&&d.expiry-d.now<3*86400&&d.expiry>d.now)txt='Your account expires soon.';
  if(txt){n.textContent=txt;n.className='notice show '+(k==='bad'||d.pct_total>=90?'bad':'warn')}else n.className='notice';
  var m=$('msg');if(d.message){$('msgt').textContent=d.message;m.className='msg show'}else m.className='msg';
  tick();
}
function tick(){
  if(!D)return;
  var cd=$('cd');
  if(!D.expiry){cd.className='cd inf'}
  else{
    cd.className='cd';
    var l=Math.max(0,Math.floor(D.expiry-(Date.now()/1000+off)));
    $('cd-d').textContent=Math.floor(l/86400);
    $('cd-h').textContent=Math.floor(l%86400/3600);
    $('cd-m').textContent=Math.floor(l%3600/60);
    $('cd-s').textContent=l%60;
  }
  var a=Math.round((Date.now()-lastOk)/1000),lv=$('live');
  if(a>20){lv.className='live off';$('lt').textContent='Reconnecting…'}
  else{lv.className='live';$('lt').textContent=a<3?'Live • just now':'Live • '+a+'s ago'}
}
var base=location.pathname.replace(/\/+$/,'');
function load(){
  return fetch(base+'/data',{cache:'no-store'}).then(function(r){
    if(r.status===404){document.body.className='dead';return null}
    if(!r.ok)throw new Error(r.status);return r.json();
  }).then(function(d){if(d)render(d)}).catch(function(){});
}
$('rf').onclick=function(){var b=this;b.textContent='…';load().then(function(){b.textContent='⟳ Refresh'})};
setInterval(function(){if(!document.hidden)load()},5000);
setInterval(tick,1000);
document.addEventListener('visibilitychange',function(){if(!document.hidden)load()});
load();
})();
</script>
</body>
</html>
'''

def v2_usage_data(mod, name, u):
    """Public-safe account summary (no UUID / password / links)."""
    now = int(time.time())
    s = v2_summary(mod, name, u, mod.load_usage(), now)
    tl = mod.quota_bytes(u.get("total_gb", 0))
    dl = mod.quota_bytes(u.get("daily_gb", 0))
    exp = int(u.get("expiry", 0) or 0)
    return {
        "name": name, "now": now,
        "proto_label": V2_PROTO_LABEL.get(s["proto"], str(s["proto"] or "V2Ray").upper()),
        "status": s["status"], "status_text": s["status_text"],
        "used": s["used"], "today": s["today"], "up": s["up"], "down": s["down"],
        "total_bytes": int(tl) if tl > 0 else 0, "daily_bytes": int(dl) if dl > 0 else 0,
        "pct_total": s["pct_total"], "pct_daily": s["pct_daily"],
        "conn_limit": s["conn_limit"], "created": int(s.get("created", 0) or 0),
        "expiry": exp,
        "expiry_date": time.strftime("%d %b %Y, %H:%M", time.localtime(exp)) if exp else "Never",
        "message": v2_read_admin_msg(name),
    }

def v2_usage_page_html(name):
    creds = get_panel_creds()
    pname = html_escape(creds.get("PANEL_NAME") or DEFAULT_PANEL_NAME)
    logo = creds.get("PANEL_LOGO") or DEFAULT_PANEL_LOGO
    if logo == "custom" and os.path.exists(LOGO_PATH):
        logo_html = '<img src="/api/logo.png" alt="">'
    else:
        logo_html = html_escape(logo)
    return (V2_USAGE_PAGE.replace("%%NAME%%", html_escape(name))
            .replace("%%PANEL%%", pname).replace("%%LOGO%%", logo_html))


# =====================================================================================
# BACKUP / RESTORE, BACKGROUND JOBS, SERVER REINSTALL, PROTOCOL CONTROL  (admin only)
# =====================================================================================
import io
import tarfile
import tempfile
import zlib
import urllib.request

# Backups use the SAME archive layout as the menu (Backup User Data / Restore User Data):
#   visibleTech/  users.db, resellers.db, bandwidth/, v2ray/, ssl/, dns_info.conf, panel.conf, ... + backup_meta
# so a file made here restores in the menu, and a file made by the menu restores here.
BACKUP_SETTINGS_FILE = DB_DIR + "/backup_settings.json"
DEFAULT_BACKUP_DIR = "/root"                    # same folder the menu uses by default
BACKUP_ROOT_NAME = "visibleTech"                # top folder inside the archive (same as the menu)
BACKUP_NAME_RE = re.compile(r'^visibleTech[A-Za-z0-9._-]{0,100}\.tar\.gz$')
BACKUP_AUTO_RE = re.compile(r'^visibleTech_users_\d{8}-\d{6}[A-Za-z0-9-]*\.tar\.gz$')   # only these are pruned
BACKUP_MAX_UPLOAD = 1024 * 1024 * 1024          # 1 GB
BAD_BACKUP_DIRS = {"/", "/etc", "/bin", "/sbin", "/usr", "/lib", "/lib64", "/boot", "/dev",
                   "/proc", "/sys", "/run", "/var", "/home", "/tmp"}
SSH_LIMITER_SERVICE = "visibleTech-limiter"
BACKUP_DOWNLOADED = {}                          # name -> time it was fully downloaded (this panel run)


def backup_clean_dir(path):
    raw = str(path or "").strip()
    if (not raw.startswith("/") or ".." in raw.split("/") or len(raw) > 200
            or re.search(r'[\x00-\x1f]', raw)):
        raise ValueError("Folder must be a full path such as /root")
    norm = os.path.normpath(raw)
    if norm in BAD_BACKUP_DIRS:
        raise ValueError("Choose a dedicated folder, not %s itself" % norm)
    return norm


def backup_settings_load():
    d = {"dir": DEFAULT_BACKUP_DIR, "keep": 10}
    try:
        with open(BACKUP_SETTINGS_FILE) as f:
            s = json.load(f)
        if isinstance(s, dict):
            if isinstance(s.get("dir"), str) and s["dir"].strip():
                d["dir"] = s["dir"].strip()
            if isinstance(s.get("keep"), int) and 1 <= s["keep"] <= 200:
                d["keep"] = s["keep"]
    except (OSError, ValueError):
        pass
    return d


def backup_settings_save(d):
    os.makedirs(DB_DIR, exist_ok=True)
    tmp = BACKUP_SETTINGS_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(d, f, indent=2)
    os.chmod(tmp, 0o600)
    os.replace(tmp, BACKUP_SETTINGS_FILE)


def backup_dir():
    d = backup_settings_load()["dir"]
    try:
        d = backup_clean_dir(d)
    except ValueError:
        d = DEFAULT_BACKUP_DIR
    os.makedirs(d, mode=0o700, exist_ok=True)
    return d


def backup_path(name):
    """Full path of an existing backup file, or None (name is validated, no path tricks)."""
    name = str(name or "")
    if not BACKUP_NAME_RE.match(name):
        return None
    p = os.path.join(backup_dir(), name)
    return p if os.path.isfile(p) else None


def backup_info(path):
    st = os.stat(path)
    name = os.path.basename(path)
    return {"name": name, "size": st.st_size, "created": int(st.st_mtime),
            "created_text": time.strftime("%Y-%m-%d %H:%M", time.localtime(st.st_mtime)),
            "downloaded": name in BACKUP_DOWNLOADED}


def backup_list():
    d = backup_dir()
    out = []
    for fn in os.listdir(d):
        p = os.path.join(d, fn)
        if BACKUP_NAME_RE.match(fn) and os.path.isfile(p):
            out.append(backup_info(p))
    out.sort(key=lambda x: x["created"], reverse=True)
    return out


def backup_prune(keep):
    """Only panel-made, time-stamped backups are pruned; the menu's own file is never touched."""
    auto = [b for b in backup_list() if BACKUP_AUTO_RE.match(b["name"])]
    for it in auto[keep:]:
        try:
            os.remove(os.path.join(backup_dir(), it["name"]))
        except OSError:
            pass


def _tar_tree(tf, root, arc_root, skip_files, skip_dir):
    skip_dir = os.path.abspath(skip_dir)
    for cur, dirs, files in os.walk(root):
        ac = os.path.abspath(cur)
        if ac == skip_dir or ac.startswith(skip_dir + os.sep):
            dirs[:] = []
            continue
        dirs[:] = [d for d in dirs if d != "pidtrack" and not d.startswith(".restore-")
                   and not os.path.islink(os.path.join(cur, d))]
        rel = os.path.relpath(cur, root)
        arc = arc_root if rel == "." else arc_root + "/" + rel.replace(os.sep, "/")
        tf.add(cur, arcname=arc, recursive=False)
        for fn in files:
            p = os.path.join(cur, fn)
            if p in skip_files or os.path.islink(p) or not os.path.isfile(p):
                continue
            if fn.endswith((".tmp", ".part")):
                continue
            try:
                tf.add(p, arcname=arc + "/" + fn, recursive=False)
            except OSError:
                pass


def backup_create(label=""):
    bdir = backup_dir()
    label = re.sub(r'[^A-Za-z0-9-]', '', str(label or ""))[:20]
    # a normal backup is always "visibleTech_users.tar.gz" (exactly what the menu writes); only the automatic
    # safety copies (pre-restore ...) get a time-stamped name, so they can never overwrite the file being restored
    if label:
        name = "visibleTech_users_%s-%s.tar.gz" % (time.strftime("%Y%m%d-%H%M%S"), label)
    else:
        name = "visibleTech_users.tar.gz"
    final = os.path.join(bdir, name)
    BACKUP_DOWNLOADED.pop(name, None)               # a new file: it has not been downloaded yet
    tmp = final + ".part"
    n_ssh, n_v2, n_res = len(read_db()), len(v2_users_safe()), len(read_resellers())
    if n_v2 and v2_installed():                     # newest V2Ray traffic counters first (same as the menu)
        v2_cli(["daemon", "--once"], timeout=20)
    meta = ("format=2\nsource=panel.py\ncreated=%s\nhost=%s\n"
            % (time.strftime("%Y-%m-%d %H:%M:%S"), socket.gethostname())).encode()
    try:
        with db_lock:                                   # consistent users.db while we copy
            with tarfile.open(tmp, "w:gz") as tf:
                _tar_tree(tf, DB_DIR, BACKUP_ROOT_NAME, {SESSION_FILE, PANEL_HTML}, bdir)
                ti = tarfile.TarInfo(BACKUP_ROOT_NAME + "/backup_meta")
                ti.size, ti.mtime, ti.mode = len(meta), int(time.time()), 0o600
                tf.addfile(ti, io.BytesIO(meta))
                if os.path.isdir(FASTDNS_DIR):          # DNSTT keys: clients keep working after a reinstall
                    _tar_tree(tf, FASTDNS_DIR, BACKUP_ROOT_NAME + "/fastdns", set(), bdir)
        os.chmod(tmp, 0o600)
        os.replace(tmp, final)
    finally:
        if os.path.exists(tmp):
            try:
                os.remove(tmp)
            except OSError:
                pass
    backup_prune(backup_settings_load()["keep"])
    info = backup_info(final)
    info["manifest"] = {"ssh_users": n_ssh, "v2ray_users": n_v2, "resellers": n_res}
    return info


def _clean_member_name(n):
    while n.startswith("./"):
        n = n[2:]
    return n.lstrip("/")


def backup_validate(path):
    """Accept a backup made by the menu or by this panel. Returns the backup_meta fields (may be empty)."""
    bad = "This is not a visibleTech user data backup"
    found, meta = False, {}
    try:
        with tarfile.open(path, "r:gz") as tf:
            for m in tf.getmembers():
                n = _clean_member_name(m.name)
                if ".." in n.split("/"):
                    raise ValueError("The file contains unsafe paths")
                if not m.isfile():
                    continue
                parts = n.split("/")
                for cand in ("/".join(parts), "/".join(parts[1:])):
                    if cand in ("users.db", "resellers.db", "v2ray/users.json") or cand.startswith("bandwidth/"):
                        found = True
                    if cand == "backup_meta" and m.size < 4096:
                        fh = tf.extractfile(m)
                        for line in (fh.read().decode("utf-8", "replace").splitlines() if fh else []):
                            if "=" in line:
                                k, v = line.split("=", 1)
                                meta[k.strip()] = v.strip()
    except ValueError:
        raise
    except (KeyError, tarfile.TarError, OSError, EOFError, zlib.error):
        raise ValueError("This is not a valid backup file")
    if not found:
        raise ValueError(bad + " (no users.db, resellers or V2Ray users inside)")
    return meta


def _safe_extract(tf, dest):
    """Extract regular files and folders only; links, devices and paths that escape dest are skipped."""
    dest = os.path.realpath(dest)
    for m in tf:
        n = _clean_member_name(m.name)
        if not n or n == ".":
            continue
        target = os.path.realpath(os.path.join(dest, n))
        if target != dest and not target.startswith(dest + os.sep):
            continue
        if m.isdir():
            os.makedirs(target, exist_ok=True)
        elif m.isfile():
            os.makedirs(os.path.dirname(target), exist_ok=True)
            src = tf.extractfile(m)
            with open(target, "wb") as out:
                shutil.copyfileobj(src, out)
            try:
                os.chmod(target, m.mode & 0o777)
                os.utime(target, (m.mtime, m.mtime))
            except OSError:
                pass


def _find_backup_src(stage):
    def ok(d):
        return (os.path.isfile(d + "/users.db") or os.path.isfile(d + "/resellers.db")
                or os.path.isdir(d + "/v2ray") or os.path.isdir(d + "/bandwidth"))
    if ok(stage):
        return stage
    for e in sorted(os.listdir(stage)):
        d = os.path.join(stage, e)
        if os.path.isdir(d) and ok(d):
            return d
    return None


def _copy_replace(src, dst, *, follow_symlinks=True):
    """Copy src over dst without opening dst for writing.
    Writing straight into a file that is running (like /etc/fastdns/dnstt-server) fails with
    'Text file busy'. Copy to a temp name in the same folder, then rename it over the target:
    the rename is atomic and works even while the old file is in use."""
    d = os.path.dirname(dst) or "."
    os.makedirs(d, exist_ok=True)
    tmp = os.path.join(d, ".%s.restore-tmp" % os.path.basename(dst))
    try:
        shutil.copy2(src, tmp)
        os.replace(tmp, dst)
    finally:
        if os.path.exists(tmp):
            try:
                os.remove(tmp)
            except OSError:
                pass
    return dst


def backup_restore(path, opts, log):
    log("Checking the backup file...")
    meta = backup_validate(path)
    if meta.get("created"):
        log("Backup made %s%s" % (meta["created"], (" on " + meta["host"]) if meta.get("host") else ""))
    os.makedirs(DB_DIR, exist_ok=True)
    try:
        log("Saving a safety copy of the current data first...")
        pre = backup_create("pre-restore")
        log("Safety copy: " + pre["name"])
    except Exception as e:
        log("Safety copy skipped: %s" % e)

    stage = tempfile.mkdtemp(prefix=".restore-", dir=DB_DIR)
    lim_was = []
    try:
        log("Unpacking...")
        with tarfile.open(path, "r:gz") as tf:
            _safe_extract(tf, stage)
        src = _find_backup_src(stage)
        if not src:
            raise RuntimeError("No users.db, bandwidth or v2ray folder found in the backup. Nothing to restore.")

        # the limiter services keep counters on disk: stop them while files are replaced (same as the menu)
        for svc in (SSH_LIMITER_SERVICE, V2_LIMITER_SERVICE):
            if run_cmd(["systemctl", "is-active", "--quiet", svc], ignore_errors=True)[0] == 0:
                lim_was.append(svc)
                run_cmd(["systemctl", "stop", svc], ignore_errors=True)

        skip = {"sessions.json", "panel/index.html", "backup_meta", "panel.conf"}
        copied = 0
        with db_lock:
            for cur, dirs, files in os.walk(src):
                rel = os.path.relpath(cur, src)
                rel = "" if rel == "." else rel
                top = rel.split(os.sep)[0] if rel else ""
                if top in ("backups", "bandwidth", "v2ray", "fastdns") or top.startswith(".restore-"):
                    dirs[:] = []
                    continue
                dst_dir = os.path.join(DB_DIR, rel)
                os.makedirs(dst_dir, exist_ok=True)
                for fn in files:
                    key = (rel.replace(os.sep, "/") + "/" + fn).lstrip("/")
                    if key in skip:
                        continue
                    _copy_replace(os.path.join(cur, fn), os.path.join(dst_dir, fn))
                    copied += 1
            if os.path.isfile(src + "/users.db"):
                log("User database restored")
            if os.path.isfile(src + "/resellers.db"):
                os.chmod(DB_DIR + "/resellers.db", 0o600)
                log("Reseller accounts restored")
            # bandwidth usage: replace the counters so the remaining bandwidth stays exactly as in the backup
            if os.path.isdir(src + "/bandwidth"):
                os.makedirs(BW_DIR, exist_ok=True)
                for fn in os.listdir(BW_DIR):
                    p = os.path.join(BW_DIR, fn)
                    if os.path.isfile(p):
                        os.remove(p)
                for fn in os.listdir(src + "/bandwidth"):
                    p = os.path.join(src + "/bandwidth", fn)
                    if os.path.isfile(p):
                        _copy_replace(p, os.path.join(BW_DIR, fn))
                os.makedirs(BW_DIR + "/pidtrack", exist_ok=True)
                log("Bandwidth usage restored")
            # panel login: like the menu, only filled in when this server has none (unless you tick the box)
            conf = DB_DIR + "/panel.conf"
            have_conf = os.path.isfile(conf) and os.path.getsize(conf) > 0
            if os.path.isfile(src + "/panel.conf") and (opts.get("panel_login") or not have_conf):
                _copy_replace(src + "/panel.conf", conf)
                os.chmod(conf, 0o600)
                log("Panel login and settings restored from the backup")
            if os.path.isdir(src + "/v2ray"):
                os.makedirs(V2_DATA_DIR, exist_ok=True)
                shutil.copytree(src + "/v2ray", V2_DATA_DIR, dirs_exist_ok=True, copy_function=_copy_replace)
                log("V2Ray users and usage restored")
            if os.path.isdir(src + "/fastdns"):
                shutil.copytree(src + "/fastdns", FASTDNS_DIR, dirs_exist_ok=True, copy_function=_copy_replace)
                log("DNSTT keys restored")
        log("Restored %d data files" % copied)

        if os.path.isdir(V2_DATA_DIR) and os.path.isfile(src + "/v2ray/users.json"):
            if v2_installed():
                code, out, err = v2_cli(["render", "--restart"], timeout=120)
                log("V2Ray configuration re-applied" if code == 0 else "V2Ray re-apply reported: %s" % (err or out)[:200])
            else:
                log("V2Ray is not installed here. Install it from the Services page; the restored accounts will then work.")

        log("Re-creating SSH accounts on this server...")
        run_cmd(["groupadd", "-f", FF_USERS_GROUP], ignore_errors=True)
        made = kept = bad = locked = 0
        today = time.strftime("%Y-%m-%d")
        try:
            with open(BW_DIR + "/current_date") as f:
                bk_date = f.read().strip() or today
        except OSError:
            bk_date = today
        for u in read_db():
            un = u["username"]
            if not re.match(r'^[a-zA-Z0-9_]{1,32}$', un):
                bad += 1
                continue
            if run_cmd(["id", un], ignore_errors=True)[0] == 0:
                kept += 1
            else:
                run_cmd(["useradd", "-m", "-s", "/usr/sbin/nologin", un], ignore_errors=True)
                made += 1
            run_cmd(["usermod", "-aG", FF_USERS_GROUP, un], ignore_errors=True)
            set_system_password(un, u["password"])
            exp = u.get("expire_date") or "Never"
            run_cmd(["chage", "-E", "-1" if exp == "Never" else exp, un], ignore_errors=True)
            # setting the password unlocked the account: keep it locked when the restored usage is over a quota
            used = read_file_int("%s/%s.usage" % (BW_DIR, un))
            if float(u.get("bandwidth_gb") or 0) > 0 and used >= round(float(u["bandwidth_gb"]) * 1073741824):
                run_cmd(["usermod", "-L", un], ignore_errors=True)
                locked += 1
            elif float(u.get("daily_bandwidth_gb") or 0) > 0 and bk_date == today:
                dused = read_file_int("%s/%s.daily_usage" % (BW_DIR, un))
                if dused >= round(float(u["daily_bandwidth_gb"]) * 1073741824):
                    run_cmd(["usermod", "-L", un], ignore_errors=True)
                    open("%s/%s.daily_locked" % (BW_DIR, un), "a").close()
                    locked += 1
        log("SSH accounts: %d created, %d already existed%s%s" % (
            made, kept, (", %d kept locked (quota used up)" % locked) if locked else "",
            (", %d skipped (bad name)" % bad) if bad else ""))
        try:
            refresh_ssh_banner_config()
        except Exception as e:
            log("Banner refresh skipped: %s" % e)
    finally:
        shutil.rmtree(stage, ignore_errors=True)
        for svc in lim_was:
            run_cmd(["systemctl", "start", svc], ignore_errors=True)
    log("Restore finished.")


# ---------------- installable app (PWA): manifest, service worker, icons ----------------
PWA_ICON_192_B64 = (
    "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")
PWA_ICON_512_B64 = (
    "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"
    "AACAAAAAEAAAAAIAAEAAAAAIAAAAAQAAIAAAAAQAAIAAAAAQAAAAAgAAQAAAAAgAAAABAAAgAAAABAAAgAAAABAAAAACAABAAAAA"
    "CAAAIAAAAAQAAIAAAAAQAAAAAgAAQAAAAAgAAAABAAAgAAAABAAAgAAAABAAAAACAABAAAAACAAAAAEAACAAAAAEAACAAAAAEAAA"
    "AAIAAEAAAAAIAAAgAPgIAIAAAAAQAAAAAgAAQAAAAAgAAAABAAAgAAAABAAAgAAAABAAAAACAABAAAAACAAAAAEAACAAAAAEAACA"
    "AAAAEAAAAAIAAEAAAAAIAAAAAQAAIAAAgAAAABAAAAACAABAAAAACAAAAAEAACAAAAAEAACAAAAAEAAAAAIAAEAAAAAIAAAAAQAA"
    "IAAAAAQAAIAAAAAQAAAAAgAAQAAAAAgAAAABAAAgAACAAAAAEAAAAAIAAEAAAAAIAAAAAQAAIAAAAAQAAIAAAAAQAAAAAgAAQAAA"
    "AAgAAAABAAAgAAAABAAAgAAAABAAAAACAABAAAAACAAAAAEAACAAAAAEAAAQAAAAAgAAQAAAAAgAAAABAAAgAAAABAAAgAAAABAA"
    "AAACAABAAAAACAAAAAEAACAAAAAEAACAAAAAEAAAAAIAAEAAAAAIAAAAAQAAIAAAAAQAABAAAAACAABAAAAACAAAAAEAACAAAAAE"
    "AACAAAAAEAAAgG72/wFiiJEpYMnN0gAAAABJRU5ErkJggg==")

PWA_SW_JS = """// visibleTech panel service worker: lets the browser install the panel as an app.
// It never caches panel data; if the server cannot be reached it shows a small offline page.
const OFFLINE = '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">' +
  '<title>Offline</title><body style="margin:0;min-height:100vh;display:grid;place-items:center;background:#0a0e22;color:#e9ecff;font:16px system-ui,sans-serif;text-align:center">' +
  '<div><h2 style="margin:0 0 .5rem">Cannot reach the server</h2><p style="color:#9bb0a6;margin:0 0 1.2rem">Check your connection, then try again.</p>' +
  '<button onclick="location.reload()" style="background:#ff7a59;color:#1d0b05;border:0;border-radius:10px;padding:.7rem 1.4rem;font-weight:700;font-size:1rem">Retry</button></div>';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', e => {
  if (e.request.mode !== 'navigate') return;
  e.respondWith(fetch(e.request).catch(() => new Response(OFFLINE, {status: 503, headers: {'Content-Type': 'text/html; charset=utf-8'}})));
});
"""
PWA_FILES = ("manifest.webmanifest", "sw.js", "icon-192.png", "icon-512.png")


# ---------------- background jobs (live log shown in the panel) ----------------
JOBS = {}
jobs_lock = threading.Lock()


def job_start(kind, title, fn):
    with jobs_lock:
        for j in JOBS.values():
            if j["status"] == "running":
                raise ValueError("Another task is still running: %s" % j["title"])
        jid = secrets.token_hex(6)
        job = {"id": jid, "kind": kind, "title": title, "status": "running",
               "log": [], "started": time.time(), "ended": None}
        JOBS[jid] = job
        for old in sorted(JOBS.values(), key=lambda x: x["started"])[:-15]:
            JOBS.pop(old["id"], None)

    def log(line):
        with jobs_lock:
            if len(job["log"]) < 3000:
                job["log"].append(_ANSI_RE.sub("", str(line)).rstrip()[:500])

    def runner():
        try:
            fn(log)
            status = "done"
        except Exception as e:
            log("ERROR: %s" % e)
            status = "error"
        with jobs_lock:
            job["status"], job["ended"] = status, time.time()

    threading.Thread(target=runner, daemon=True).start()
    return jid


def job_public(job, since=0):
    with jobs_lock:
        return {"id": job["id"], "kind": job["kind"], "title": job["title"], "status": job["status"],
                "log": job["log"][since:], "next": len(job["log"]), "started": int(job["started"])}


def run_streaming(cmd, log, timeout=1800, input_text=None, cwd=None):
    env = dict(os.environ, HOME=os.environ.get("HOME") or "/root",
               PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", LC_ALL="C.UTF-8", LANG="C.UTF-8")
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE if input_text is not None else subprocess.DEVNULL,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True, bufsize=1,
                         cwd=cwd, env=env)
    timer = threading.Timer(timeout, p.kill)
    timer.start()
    try:
        if input_text is not None:
            try:
                p.stdin.write(input_text)
                p.stdin.close()
            except OSError:
                pass
        for line in p.stdout:
            line = line.rstrip()
            if line:
                log(line)
        return p.wait()
    finally:
        timer.cancel()


# ---------------- server reinstall (bin456789/reinstall) ----------------
# Mirrors every option of the menu script reinstall.sh: Linux (all systems), Windows, DD image, Alpine Live,
# netboot.xyz and "cancel a pending reinstall".
REINSTALL_URL = "https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
REINSTALL_URLS = [REINSTALL_URL, "https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.sh"]
REINSTALL_DIR = "/root/reinstall-engine"

# (name, key, versions, type)   type: ver = pick a version | rolling = no version | redhat = needs a qcow2 link
REINSTALL_LINUX = [
    ("Ubuntu", "ubuntu", ["18.04", "20.04", "22.04", "24.04", "26.04"], "ver"),
    ("Debian", "debian", ["9", "10", "11", "12", "13"], "ver"),
    ("Kali Linux", "kali", ["last-snapshot", "rolling"], "ver"),
    ("Alpine", "alpine", ["3.21", "3.22", "3.23", "3.24"], "ver"),
    ("AlmaLinux", "almalinux", ["8", "9", "10"], "ver"),
    ("Rocky Linux", "rocky", ["8", "9", "10"], "ver"),
    ("Oracle Linux", "oracle", ["8", "9", "10"], "ver"),
    ("CentOS Stream", "centos", ["9", "10"], "ver"),
    ("Fedora", "fedora", ["43", "44"], "ver"),
    ("Anolis OS", "anolis", ["7", "8", "23"], "ver"),
    ("OpenCloudOS", "opencloudos", ["8", "9", "23"], "ver"),
    ("openEuler", "openeuler", ["20.03", "22.03", "24.03", "26.09"], "ver"),
    ("openSUSE", "opensuse", ["16.0", "tumbleweed"], "ver"),
    ("NixOS", "nixos", ["26.05"], "ver"),
    ("Arch Linux", "arch", [], "rolling"),
    ("Gentoo", "gentoo", [], "rolling"),
    ("AOSC OS", "aosc", [], "rolling"),
    ("fnOS", "fnos", ["1"], "ver"),
    ("FygoOS", "fygoos", ["1"], "ver"),
    ("Red Hat", "redhat", [], "redhat"),
]
REINSTALL_BY_KEY = {k: (n, v, t) for n, k, v, t in REINSTALL_LINUX}
REINSTALL_MODES = ("linux", "windows", "dd", "live", "netboot", "reset")

# Password: any printable ASCII character (no spaces), 4-128 long, not starting with "-".
# It is passed to the installer as a plain argument (no shell). The form warns about symbols that some installers
# change internally, but it no longer blocks them.
REINSTALL_PW_RE = re.compile(r'^[\x21-\x2c\x2e-\x7e][\x21-\x7e]{3,127}$')
REINSTALL_USER_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_.-]{0,31}$')
REINSTALL_VER_RE = re.compile(r'^[A-Za-z0-9._-]{1,32}$')
REINSTALL_URL_RE = re.compile(r'^https?://[^\s\'"`\\]{4,2000}$')
REINSTALL_NAME_RE = re.compile(r'^[A-Za-z0-9 ().,_-]{3,80}$')
REINSTALL_LANG_RE = re.compile(r'^[a-z]{2,3}(-[A-Za-z]{2,4}){1,2}$')


def reinstall_sysinfo():
    info = {"host": socket.gethostname(), "ip": "", "os": "Linux", "arch": os.uname().machine,
            "boot": "EFI" if os.path.isdir("/sys/firmware/efi") else "BIOS", "ram": "", "disk": "", "virt": "none"}
    try:
        info["ip"] = (run_cmd(["hostname", "-I"], ignore_errors=True)[1].split() or [""])[0]
    except Exception:
        pass
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    info["os"] = line.split("=", 1)[1].strip().strip('"')
        with open("/proc/meminfo") as f:
            kb = int(f.readline().split()[1])
            info["ram"] = "%d MB" % (kb // 1024)
    except Exception:
        pass
    try:
        out = run_cmd(["lsblk", "-dnbo", "SIZE,TYPE"], ignore_errors=True)[1]
        total = sum(int(l.split()[0]) for l in out.splitlines() if len(l.split()) == 2 and l.split()[1] == "disk")
        if total:
            info["disk"] = "%d GB" % round(total / 1073741824)
    except Exception:
        pass
    v = run_cmd(["systemd-detect-virt"], ignore_errors=True)[1]
    info["virt"] = v or "none"
    return info


def reinstall_catalog():
    return {"linux": [{"name": n, "key": k, "versions": v, "type": t} for n, k, v, t in REINSTALL_LINUX],
            "info": reinstall_sysinfo()}


def reinstall_build(body):
    """Validate the form and build the engine arguments exactly like the menu does.
    Returns (args, label, destructive, reboots). Raises ValueError with a message for the user."""
    mode = str(body.get("mode", "linux")).lower()
    if mode not in REINSTALL_MODES:
        raise ValueError("Unknown reinstall mode")
    s = lambda k: str(body.get(k) or "").strip()
    args, destructive, reboots = [], True, True

    def need_password():
        pw = str(body.get("password") or "")
        if not REINSTALL_PW_RE.match(pw):
            raise ValueError("Password: 4-128 characters, no spaces, cannot start with -")
        return pw

    def common(want_key, password_required=True):
        user = s("username")
        if user:
            if not REINSTALL_USER_RE.match(user):
                raise ValueError("Username: letters, digits, _ . - only (max 32), must start with a letter")
            args.extend(["--username", user])
        if password_required or str(body.get("password") or ""):
            args.extend(["--password", need_password()])
        port = s("ssh_port")
        if port:
            if not port.isdigit() or not (1 <= int(port) <= 65535):
                raise ValueError("SSH port must be 1-65535")
            args.extend(["--ssh-port", port])
        if want_key:
            key = s("ssh_key")
            if key:
                if len(key) > 4096 or "\n" in key or "\r" in key:
                    raise ValueError("SSH key must be one line (public key, URL or github:USER)")
                args.extend(["--ssh-key", key])

    if mode == "linux":
        key = s("os").lower()
        if key not in REINSTALL_BY_KEY:
            raise ValueError("Choose a system from the list")
        name, versions, typ = REINSTALL_BY_KEY[key]
        args.append(key)
        label = name
        if typ == "ver":
            ver = s("version")
            if ver:
                if ver not in versions and not REINSTALL_VER_RE.match(ver):
                    raise ValueError("Invalid version")
                args.append(ver)
                label += " " + ver
            else:
                label += " (latest)"
        elif typ == "redhat":
            img = s("img")
            if not REINSTALL_URL_RE.match(img):
                raise ValueError("Red Hat needs the official qcow2 image link (http/https)")
            args.append("--img=" + img)
        if key == "ubuntu" and body.get("minimal"):
            args.append("--minimal")
        common(True)
    elif mode == "windows":
        name = s("image_name") or "Windows 11 Pro"
        lang = s("lang") or "en-us"
        if not REINSTALL_NAME_RE.match(name):
            raise ValueError("Image name has invalid characters")
        if not REINSTALL_LANG_RE.match(lang):
            raise ValueError("Language must look like en-us, fr-fr, zh-cn")
        args = ["windows", "--image-name", name, "--lang", lang]
        iso = s("iso")
        if iso:
            if not REINSTALL_URL_RE.match(iso):
                raise ValueError("ISO link must start with http:// or https://")
            args.extend(["--iso", iso])
        rdp = s("rdp_port")
        if rdp:
            if not rdp.isdigit() or not (1 <= int(rdp) <= 65535):
                raise ValueError("RDP port must be 1-65535")
            args.extend(["--rdp-port", rdp])
        if body.get("allow_ping"):
            args.append("--allow-ping")
        common(False)
        label = name
    elif mode == "dd":
        img = s("img")
        if not REINSTALL_URL_RE.match(img):
            raise ValueError("DD image link must start with http:// or https://")
        args = ["dd", "--img", img]
        common(True, password_required=False)
        label = "DD image"
    elif mode == "live":
        args, destructive = ["alpine", "--hold", "1"], False
        common(True)
        label = "Alpine Live OS"
    elif mode == "netboot":
        args, destructive = ["netboot.xyz"], False
        label = "netboot.xyz"
    else:
        args, destructive, reboots = ["reset"], False, False
        label = "Cancel pending reinstall"
    return args, label, destructive, reboots


def reinstall_mask(args):
    out, hide = [], False
    for a in args:
        out.append("'****'" if hide else shlex.quote(a))
        hide = (a == "--password")
    return " ".join(out)


def _reinstall_download(log):
    """Try every mirror; accept only a real, syntactically valid shell script."""
    last = "unknown error"
    os.makedirs(REINSTALL_DIR, exist_ok=True)
    for url in REINSTALL_URLS:
        try:
            log("Downloading the reinstall script from %s ..." % url.split("/")[2])
            req = urllib.request.Request(url, headers={"User-Agent": "visibleTech-panel"})
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            if not data.startswith(b"#!"):
                last = "the downloaded file is not a script"
                continue
            tmp = REINSTALL_DIR + "/reinstall.sh.new"
            with open(tmp, "wb") as f:
                f.write(data)
            if subprocess.run(["bash", "-n", tmp]).returncode != 0:
                last = "the downloaded script is damaged"
                continue
            path = REINSTALL_DIR + "/reinstall.sh"
            os.replace(tmp, path)
            os.chmod(path, 0o700)
            return path
        except Exception as e:
            last = str(e)
            log("  failed: %s" % last)
    raise RuntimeError("Could not download reinstall.sh (%s). Check DNS / outbound access to GitHub." % last)


def _reinstall_preflight(log):
    """Fail early with a clear reason instead of a cryptic engine error."""
    if os.geteuid() != 0:
        raise RuntimeError("The panel must run as root to reinstall the server")
    virt = run_cmd(["systemd-detect-virt"], ignore_errors=True)[1]
    if virt in ("openvz", "lxc", "lxc-libvirt", "docker", "podman"):
        raise RuntimeError("This server is a %s container. Reinstall only works on KVM/Xen/VMware/dedicated machines." % virt)
    for tool in ("curl", "awk", "ip"):
        if not shutil.which(tool):
            raise RuntimeError("Required tool '%s' is missing. Install it first (apt install curl gawk iproute2)." % tool)
    free_mb = None
    try:
        st = os.statvfs("/")
        free_mb = st.f_bavail * st.f_frsize // 1048576
    except OSError:
        pass
    if free_mb is not None and free_mb < 600:
        raise RuntimeError("Only %d MB free on / (need at least 600 MB for the installer files)" % free_mb)
    log("Check: virtualization=%s, free disk=%s MB" % (virt or "none", free_mb if free_mb is not None else "?"))


def reinstall_run(args, label, reboots, login_note, log):
    _reinstall_preflight(log)
    path = _reinstall_download(log)
    cmd = ["bash", path] + args
    # The panel service has MemoryHigh/MemoryMax limits (128M/256M). The installer unpacks and rebuilds an initrd,
    # which needs more than that (exit 137). Run it in its own scope, outside those limits.
    if shutil.which("systemd-run"):
        cmd = ["systemd-run", "--scope", "--quiet", "-p", "MemoryHigh=infinity", "-p", "MemoryMax=infinity"] + cmd
    log("Preparing: %s" % label)
    log("$ ./reinstall.sh %s" % reinstall_mask(args))
    code = run_streaming(cmd, log, timeout=1800, input_text="y\ny\ny\ny\ny\n", cwd=REINSTALL_DIR)
    if code != 0:
        hint = ""
        if code in (137, -9):
            hint = " (killed - out of memory; add swap or RAM and try again)"
        elif code == -15:
            hint = " (timed out)"
        raise RuntimeError("reinstall.sh stopped with code %d%s - the server was NOT changed. Read the lines above for the exact reason." % (code, hint))
    if not reboots:
        log("Done. The pending reinstall was cancelled. Nothing was changed and no reboot is needed.")
        return
    log("Preparation finished. The server restarts in 10 seconds.")
    log("This panel goes offline now. It takes about 5-30 minutes.")
    if login_note:
        log(login_note)

    def _go():
        try:
            subprocess.run(["sync"])
        finally:
            subprocess.run(["reboot"])
    threading.Timer(10, _go).start()


# ---------------- protocol control ----------------
PROTO_ACTIONS = ("start", "stop", "restart", "enable", "disable")
MENU_SCRIPT = os.environ.get("PANEL_MENU", "/usr/local/bin/menu")
PROTO_INSTALLERS_FILE = DB_DIR + "/protocol_installers.json"


def proto_find(service):
    return next((p for p in PROTOCOLS if p["service"] == service), None)


def proto_installer(service, action):
    """Command that installs/removes a protocol, or None when this server has no installer for it.
    1) DB_DIR/protocol_installers.json  {"service": {"install": "...", "uninstall": "..."}}
    2) a menu script that understands:  menu --panel-protocol install|uninstall <service>"""
    try:
        with open(PROTO_INSTALLERS_FILE) as f:
            cmd = (json.load(f).get(service) or {}).get(action)
        if cmd:
            return ["bash", "-c", str(cmd)]
    except (OSError, ValueError, AttributeError):
        pass
    try:
        with open(MENU_SCRIPT, "rb") as f:
            if b"--panel-protocol" in f.read():
                return ["bash", MENU_SCRIPT, "--panel-protocol", action, service]
    except OSError:
        pass
    return None


def _run_installer(cmd, log):
    code = run_streaming(cmd, log, timeout=1800)
    if code != 0:
        raise RuntimeError("The installer stopped with code %d" % code)
    log("Finished.")


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

            # Public V2Ray subscription (token-protected, no panel login): /sub/<name>/<token>
            sub_path = raw_path
            if secret and sub_path.startswith("/" + secret + "/"):
                sub_path = sub_path[len(secret) + 1:]
            ms = V2_SUB_RE.match(sub_path)
            if ms:
                return self.handle_v2_subscription(ms.group(1), ms.group(2), parse_qs(parsed_path.query))

            # Public usage page for a client (token-protected, no panel login): /u/<name>/<token>
            mu = V2_USAGE_RE.match(sub_path)
            if mu:
                return self.handle_v2_usage(mu.group(1), mu.group(2), bool(mu.group(3)))

            # Installable-app files (public, no login needed): manifest, service worker, icons
            base = "/" + secret + "/" if secret else "/"
            pwa_rel = raw_path[len(base):] if raw_path.startswith(base) else None
            if pwa_rel in PWA_FILES:
                return self.handle_pwa(pwa_rel, base)

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
                        content = f.read().replace(b"%%BASE%%", base.encode())
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
            elif api_path == "/api/backup/list":
                if not self._require_admin(session):
                    return
                self.handle_backup_list()
            elif api_path == "/api/backup/download":
                if not self._require_admin(session):
                    return
                self.handle_backup_download(parse_qs(parsed_path.query))
            elif api_path == "/api/jobs":
                if not self._require_admin(session):
                    return
                self.handle_jobs_list()
            elif api_path.startswith("/api/jobs/"):
                if not self._require_admin(session):
                    return
                self.handle_job_get(api_path.split("/")[3], parse_qs(parsed_path.query))
            elif api_path == "/api/system/reinstall/options":
                if not self._require_admin(session):
                    return
                self.handle_reinstall_options()
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
        
        if path == "/api/backup/upload":
            session = self._get_session()
            if not session:
                return
            if not self._require_admin(session):
                return
            try:
                self.handle_backup_upload(parse_qs(parsed_path.query), content_length)
            except Exception as e:
                print(f"Backup upload error: {e}", file=sys.stderr)
                self.send_json(500, {"error": str(e)})
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
        elif path == "/api/users/cleanup":
            self.handle_cleanup_expired_users(session)
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
            self.handle_protocol_action(service, "restart")
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
        elif path in ("/api/backup/create", "/api/backup/delete", "/api/backup/restore",
                      "/api/backup/settings", "/api/system/reinstall"):
            if not self._require_admin(session):
                return
            try:
                {"/api/backup/create": lambda: self.handle_backup_create(),
                 "/api/backup/delete": lambda: self.handle_backup_delete(body),
                 "/api/backup/restore": lambda: self.handle_backup_restore(body),
                 "/api/backup/settings": lambda: self.handle_backup_settings(body),
                 "/api/system/reinstall": lambda: self.handle_reinstall(body)}[path]()
            except Exception as e:
                print(f"Error handling POST {path}: {e}", file=sys.stderr)
                self.send_json(500, {"error": str(e)})
        elif path.startswith("/api/protocols/") and path.count("/") == 4:
            if not self._require_admin(session):
                return
            svc, act = path.split("/")[3], path.split("/")[4]
            if act in ("install", "uninstall"):
                self.handle_protocol_install(svc, act)
            else:
                self.handle_protocol_action(svc, act)
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
                data["slowdns"] = bool(r.get("slowdns"))
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

            if rtype == "v2ray":
                ssh_used = ssh_daily = 0
                _vm = v2_usage_by_owner().get(session["username"], [0, 0, 0])
                gen_used, gen_daily = _vm[1], _vm[2]
            else:
                ssh_used = sum(ssh_usage_of(x["username"])[0] for x in owned_users)
                ssh_daily = sum(ssh_usage_of(x["username"])[1] for x in owned_users)
                gen_used, gen_daily = ssh_used, ssh_daily

            self.send_json(200, {
                "user_count": created,
                "online_sessions": online_total,
                "protocols": [],
                "reseller_info": {
                    "ssh_used_bytes": ssh_used,
                    "ssh_daily_used_bytes": ssh_daily,
                    "used_bytes": gen_used,
                    "daily_used_bytes": gen_daily,
                    "max_users": r["max_users"] if r else 0,
                    "max_conn": r.get("max_conn", 0) if r else 0,
                    "created_users": created,
                    "expire_date": r["expire_date"] if r else "N/A",
                    "type": rtype,
                    "protos": reseller_protos(r),
                    "slowdns": bool(r and r.get("slowdns"))
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
            "ssh_used_bytes": sum(ssh_usage_of(x["username"])[0] for x in users),
            "ssh_daily_used_bytes": sum(ssh_usage_of(x["username"])[1] for x in users),
            "v2ray_count": len(v2_users),
            "v2ray_used_bytes": sum(a[1] for a in v2_usage_by_owner().values()),
            "v2ray_daily_used_bytes": sum(a[2] for a in v2_usage_by_owner().values()),
            "online_sessions": online_sessions,
            "online_ssh": online_ssh,
            "online_v2ray": online_v2,
            "protocols": procs
        })

    def get_protocols_status(self, detail=False):
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
            if "port_confs" in p:
                vals = []
                for cf in p["port_confs"]:
                    v = conf_value(*cf).replace(" ", ",")
                    if v:
                        vals.append(v)
                if vals:
                    port_txt = ",".join(vals)
            item = {
                "name": p["name"],
                "service": p["service"],
                "installed": installed,
                "running": running,
                "port": port_txt
            }
            if detail:
                item["enabled"] = bool(installed and run_cmd(["systemctl", "is-enabled", p["service"]], ignore_errors=True)[0] == 0)
                item["can_install"] = p["service"] not in ("sshd", "ssh") and proto_installer(p["service"], "install") is not None
                item["can_manage"] = bool(installed)
            procs.append(item)
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

        summary = {}
        for r_ in result:
            s_ = summary.setdefault(r_.get("owner") or "admin", {"accounts": 0, "online": 0, "used_bytes": 0, "daily_used_bytes": 0})
            s_["accounts"] += 1
            s_["online"] += r_["online_sessions"]
            s_["used_bytes"] += r_["total_used_bytes"]
            s_["daily_used_bytes"] += r_["daily_used_bytes"]

        self.send_json(200, {"users": result, "summary": summary})

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
        set_system_password(un, pwd)
        
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
            bw = round(float(body.get("bandwidth_gb", 0)), 4)
            dbw = round(float(body.get("daily_bandwidth_gb", 0)), 4)

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
            bw = round(float(body.get("bandwidth_gb", 0)), 4)
            dbw = round(float(body.get("daily_bandwidth_gb", 0)), 4)

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
            bw = round(float(body.get("bandwidth_gb", 0)), 4)

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
        """Edit an SSH account.
        Admin  : everything (username, password, expiry, devices, bandwidth limits, used bandwidth, owner)
                 on ANY account, including the ones created by resellers.
        Reseller: only password / days / devices / bandwidth limits of his own accounts."""
        if not self._check_user_ownership(username, session):
            return self.send_json(403, {"error": "Access denied"})
        if not isinstance(body, dict):
            return self.send_json(400, {"error": "Invalid request"})
        is_admin = session.get("role") == "admin"
        admin_only = [k for k in ("new_username", "owner", "expire_date", "used_gb", "daily_used_gb") if k in body]
        if admin_only and not is_admin:
            return self.send_json(403, {"error": "Only the admin can change: " + ", ".join(admin_only)})

        with db_lock:
            users = read_db()
            idx = next((i for i, x in enumerate(users) if x["username"] == username), -1)
            if idx == -1:
                return self.send_json(404, {"error": "User not found"})
            u = users[idx]
            old_name = username
            new_name = old_name
            ch = {}

            # ---- validate everything first, change nothing until all values are good ----
            try:
                if "password" in body:
                    pwd = str(body["password"])
                    if not pwd or any(c in pwd for c in ":\r\n"):
                        raise ValueError("Password cannot be empty or contain ':' or line breaks")
                    ch["password"] = pwd
                if "days" in body:
                    dd = int(body["days"])
                    if dd < 0:
                        raise ValueError("Days must be 0 or more")
                    ch["expire_date"] = calculate_expire_date(dd)
                if "expire_date" in body:
                    v = str(body["expire_date"]).strip()
                    if v != "Never":
                        try:
                            datetime.strptime(v, "%Y-%m-%d")
                        except ValueError:
                            raise ValueError("Invalid expiry date (use YYYY-MM-DD)")
                    ch["expire_date"] = v
                if "conn_limit" in body:
                    cl = int(body["conn_limit"])
                    if cl < 1:
                        raise ValueError("Devices must be at least 1")
                    if session.get("role") == "reseller":
                        err = reseller_conn_error(get_reseller(session), cl)
                        if err:
                            return self.send_json(403, {"error": err})
                    ch["conn_limit"] = cl
                for key in ("bandwidth_gb", "daily_bandwidth_gb"):
                    if key in body:
                        fv = round(float(body[key]), 4)
                        if fv < 0:
                            raise ValueError("Bandwidth cannot be negative")
                        ch[key] = fv
                for key, out_key in (("used_gb", "used_bytes"), ("daily_used_gb", "daily_used_bytes")):
                    if key in body:
                        fv = float(body[key])
                        if fv < 0:
                            raise ValueError("Used bandwidth cannot be negative")
                        ch[out_key] = int(fv * GB_BYTES)
                if "owner" in body:
                    no = str(body["owner"]).strip() or "admin"
                    if no != "admin" and not any(r["username"] == no and r["rtype"] == "ssh" for r in read_resellers()):
                        raise ValueError("Owner must be admin or an existing SSH reseller")
                    ch["owner"] = no
                if "new_username" in body:
                    nn = str(body["new_username"]).strip()
                    if nn and nn != old_name:
                        if not re.match(r'^[a-zA-Z0-9_]{3,32}$', nn):
                            raise ValueError("Invalid username (3-32 letters, digits or _)")
                        if any(x["username"] == nn for x in users):
                            raise ValueError("Username already exists in DB")
                        if run_cmd(["id", nn], ignore_errors=True)[0] == 0:
                            raise ValueError("Username already exists on the system")
                        new_name = nn
            except (ValueError, TypeError) as ex:
                return self.send_json(400, {"error": str(ex) or "Invalid value"})

            # quota state BEFORE the edit (used later to release a bandwidth lock when the edit fixes it)
            used0, dused0 = ssh_usage_of(old_name)

            def _over(tot_gb, day_gb, used, dused):
                return (tot_gb > 0 and used >= tot_gb * GB_BYTES) or (day_gb > 0 and dused >= day_gb * GB_BYTES)
            was_over = _over(u["bandwidth_gb"], u["daily_bandwidth_gb"], used0, dused0)

            # ---- apply ----
            if new_name != old_name:
                run_cmd(["pkill", "-9", "-u", old_name], ignore_errors=True)
                time.sleep(0.5)
                code, _, err = run_cmd(["usermod", "-l", new_name, old_name])
                if code != 0:
                    return self.send_json(500, {"error": "Could not rename the system user: " + (err or "usermod failed")})
                run_cmd(["groupmod", "-n", new_name, old_name], ignore_errors=True)
                run_cmd(["usermod", "-d", "/home/" + new_name, "-m", new_name], ignore_errors=True)
                rename_ssh_user_files(old_name, new_name)
                u["username"] = new_name

            if "password" in ch:
                u["password"] = ch["password"]
                set_system_password(new_name, u["password"])
            if "expire_date" in ch:
                u["expire_date"] = ch["expire_date"]
                run_cmd(["chage", "-E", "-1" if u["expire_date"] == "Never" else u["expire_date"], new_name])
            for key in ("conn_limit", "bandwidth_gb", "daily_bandwidth_gb", "owner"):
                if key in ch:
                    u[key] = ch[key]
            if "used_bytes" in ch or "daily_used_bytes" in ch:
                os.makedirs(BW_DIR, exist_ok=True)
                if "used_bytes" in ch:
                    with open(f"{BW_DIR}/{new_name}.usage", "w") as f:
                        f.write(str(ch["used_bytes"]))
                if "daily_used_bytes" in ch:
                    with open(f"{BW_DIR}/{new_name}.daily_usage", "w") as f:
                        f.write(str(ch["daily_used_bytes"]))

            # a quota lock is released only when this edit really brings the account back under its quotas
            used1, dused1 = ssh_usage_of(new_name)
            if was_over and not _over(u["bandwidth_gb"], u["daily_bandwidth_gb"], used1, dused1):
                run_cmd(["usermod", "-U", new_name], ignore_errors=True)
                run_cmd(f"rm -f {BW_DIR}/{new_name}.conn_locked {BW_DIR}/{new_name}.daily_locked", ignore_errors=True)

            with open(DB_FILE, "r") as f:
                lines = f.readlines()
            with open(DB_FILE, "w") as f:
                for line in lines:
                    if line.startswith(f"{old_name}:"):
                        f.write(format_db_line(u))
                    else:
                        f.write(line)

        if new_name != old_name:
            refresh_ssh_banner_config()
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

    def handle_cleanup_expired_users(self, session):
        """Delete every expired SSH account. Admin: all of them. Reseller: only their own."""
        import glob as _glob
        is_admin = session.get("role") == "admin"
        me = session.get("username")
        now = datetime.now()
        name_ok = re.compile(r'^[A-Za-z_][A-Za-z0-9_.-]{0,31}$')
        with db_lock:
            expired = []
            for u in read_db():
                if not is_admin and u.get("owner", "admin") != me:
                    continue
                ed = u.get("expire_date")
                if not ed or ed == "Never":
                    continue
                try:
                    if datetime.strptime(ed, "%Y-%m-%d") < now and name_ok.match(u["username"]):
                        expired.append(u["username"])
                except ValueError:
                    continue
        if not expired:
            return self.send_json(200, {"success": True, "removed": 0, "users": [],
                                        "message": "No expired accounts found"})
        for un in expired:
            force_delete_system_user(un)
        gone = set(expired)
        with db_lock:
            lines = []
            if os.path.exists(DB_FILE):
                with open(DB_FILE, "r") as f:
                    lines = f.readlines()
                with open(DB_FILE, "w") as f:
                    for line in lines:
                        if line.split(":", 1)[0] not in gone:
                            f.write(line)
        for un in expired:
            for p in _glob.glob("%s/%s.*" % (BW_DIR, un)):
                try:
                    os.remove(p)
                except OSError:
                    pass
            try:
                os.remove("%s/%s.txt" % (BANNER_DIR, un))
            except OSError:
                pass
        refresh_ssh_banner_config()
        self.send_json(200, {"success": True, "removed": len(expired), "users": expired,
                             "message": "Removed %d expired account(s)" % len(expired)})

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
        self.send_json(200, self.get_protocols_status(detail=True))

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
            "has_custom_logo": os.path.exists(LOGO_PATH) and creds.get("PANEL_LOGO") == "custom",
            "panel_domain": creds.get("PANEL_DOMAIN", ""),
            "detected_domains": detected_server_domains()
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

        new_domain = None          # None = field not sent, keep the saved domain; "" = clear it
        if "panel_domain" in body:
            try:
                new_domain = clean_panel_domain(body.get("panel_domain"))
            except ValueError as e:
                return self.send_json(400, {"error": str(e)})

        write_panel_creds(new_user, new_pwd, secret=new_secret, panel_name=new_name or None, panel_logo=new_logo or None, panel_domain=new_domain)
        self.send_json(200, {"success": True, "secret": new_secret, "panel_name": new_name or creds.get("PANEL_NAME", DEFAULT_PANEL_NAME), "panel_logo": new_logo or creds.get("PANEL_LOGO", "🦅"),
                             "panel_domain": creds.get("PANEL_DOMAIN", "") if new_domain is None else new_domain})

    # --- RESELLER HANDLERS (admin only) ---
    def handle_get_resellers(self):
        resellers = read_resellers()
        users = read_db()
        v2_users = v2_users_safe()
        usage_map = ssh_usage_by_owner(users)
        v2_map = v2_usage_by_owner()
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
                "ssh_used_bytes": 0 if r["rtype"] == "v2ray" else usage_map.get(r["username"], [0, 0, 0])[1],
                "ssh_daily_used_bytes": 0 if r["rtype"] == "v2ray" else usage_map.get(r["username"], [0, 0, 0])[2],
                "used_bytes": (v2_map if r["rtype"] == "v2ray" else usage_map).get(r["username"], [0, 0, 0])[1],
                "daily_used_bytes": (v2_map if r["rtype"] == "v2ray" else usage_map).get(r["username"], [0, 0, 0])[2],
                "enabled": r["enabled"],
                "is_expired": is_expired,
                "type": r["rtype"],
                "protos": r["protos"],
                "slowdns": bool(r.get("slowdns"))
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
                "protos": protos,
                "slowdns": bool(body.get("slowdns")) and rtype == "v2ray"
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

        r = dict(resellers[idx])
        old_name, old_type = r["username"], r["rtype"]
        pass_changed = False
        try:
            # ---- validate everything first, change nothing until it all passes ----
            new_name = str(body.get("new_username", "") or "").strip()
            if new_name and new_name != old_name:
                if not re.match(r'^[a-zA-Z0-9_]{3,32}$', new_name):
                    return self.send_json(400, {"error": "Invalid username (3-32 chars, alphanumeric + underscore)"})
                creds = get_panel_creds()
                if new_name == creds.get("PANEL_USER") or new_name.lower() == "admin":
                    return self.send_json(400, {"error": "Username conflicts with admin"})
                if any(x["username"] == new_name for x in resellers):
                    return self.send_json(400, {"error": "Another reseller already uses this username"})
            else:
                new_name = old_name

            new_type = str(body.get("type", "") or old_type).strip().lower()
            if new_type not in RESELLER_TYPES:
                return self.send_json(400, {"error": "Reseller type must be SSH or V2Ray"})
            r["rtype"] = new_type

            if body.get("password"):
                r["password"] = str(body["password"])
                pass_changed = True

            days = body.get("days")
            if days not in (None, ""):
                days = int(days)
                if days < 1:
                    return self.send_json(400, {"error": "Days must be at least 1"})
                r["expire_date"] = calculate_expire_date(days)
            elif body.get("expire_date"):
                ed = str(body["expire_date"]).strip()
                try:
                    datetime.strptime(ed, "%Y-%m-%d")
                except ValueError:
                    return self.send_json(400, {"error": "Invalid expiry date"})
                r["expire_date"] = ed

            if "max_users" in body:
                mu = int(body["max_users"])
                if mu < 1:
                    return self.send_json(400, {"error": "Max accounts must be at least 1"})
                r["max_users"] = mu
            if "max_conn" in body:
                mc = int(body["max_conn"] or 0)
                if mc < 0 or mc > 1000:
                    return self.send_json(400, {"error": "Max connections per account must be 0-1000 (0 = no limit)"})
                r["max_conn"] = mc

            if new_type == "v2ray":
                if "protos" in body:
                    protos = norm_protos(body["protos"])
                    if not protos:
                        return self.send_json(400, {"error": "Choose at least one V2Ray protocol"})
                    r["protos"] = protos
                elif old_type != "v2ray":
                    r["protos"] = ["all"]
                if "slowdns" in body:
                    r["slowdns"] = bool(body["slowdns"])
                elif old_type != "v2ray":
                    r["slowdns"] = False
            else:
                r["protos"] = []
                r["slowdns"] = False
        except (TypeError, ValueError):
            return self.send_json(400, {"error": "Invalid number in the form"})

        # ---- apply ----
        renamed = new_name != old_name
        moved = (0, 0)
        if renamed:
            try:
                moved = reassign_owner(old_name, new_name)
            except Exception as e:
                try:
                    reassign_owner(new_name, old_name)     # best-effort rollback
                except Exception:
                    pass
                return self.send_json(500, {"error": "Rename failed: %s" % e})
            r["username"] = new_name
        resellers[idx] = r
        write_resellers(resellers)

        # he must log in again after a rename or a service change (tabs / permissions change)
        if renamed or new_type != old_type:
            tokens = [t for t, s in sessions.items()
                      if s.get("username") == old_name and s.get("role") == "reseller"]
            for t in tokens:
                del sessions[t]
            if tokens:
                save_sessions()
        self.send_json(200, dict(r, type=r["rtype"], renamed=renamed,
                                 moved_ssh=moved[0], moved_v2ray=moved[1]))

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

    def handle_v2_subscription(self, name, token, qs):
        def deny():
            self.send_response(404)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(b"404 Not Found\n")
        try:
            if not v2_installed():
                return deny()
            mod = v2_module()
            u = mod.load_users().get(name) if mod else None
            if not u or not hmac.compare_digest(token, v2_sub_token(name, u)):
                return deny()
            with_info = qs.get("info", ["1"])[0] != "0"
            headers, body = v2_build_subscription(mod, name, u, with_info)
            self.send_response(200)
            for k, v in headers.items():
                self.send_header(k, v)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except Exception as e:
            print("subscription error: %s" % e, file=sys.stderr)
            try:
                deny()
            except Exception:
                pass

    def handle_v2_usage(self, name, token, is_data):
        def deny():
            body = b"404 Not Found\n"
            self.send_response(404)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.send_header('Cache-Control', 'no-store')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        try:
            if not v2_installed():
                return deny()
            mod = v2_module()
            u = mod.load_users().get(name) if mod else None
            if not u or not hmac.compare_digest(token, v2_sub_token(name, u)):
                return deny()
            if is_data:
                return self.send_json(200, v2_usage_data(mod, name, u),
                                      {"Cache-Control": "no-store", "X-Robots-Tag": "noindex"})
            body = v2_usage_page_html(name).encode("utf-8")
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Robots-Tag', 'noindex, nofollow')
            self.send_header('Referrer-Policy', 'no-referrer')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except Exception as e:
            print("usage page error: %s" % e, file=sys.stderr)
            try:
                deny()
            except Exception:
                pass

    def _v2_usage_url(self, name, u):
        """Normal browser link the client can open to see his usage."""
        host = self.headers.get("X-Forwarded-Host") or self.headers.get("Host") or ""
        scheme = self.headers.get("X-Forwarded-Proto") or "http"
        if not host:
            return ""
        return "%s://%s/u/%s/%s" % (scheme, host, name, v2_sub_token(name, u))

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
                "usage_url": self._v2_usage_url(name, u),
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
                    "allowed_protos": list(V2_PROTOS) if is_admin else reseller_protos(actor[1]),
                    "slowdns": slowdns_allowed(actor)}
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
            if sub == "slowdns" and len(parts) == 3:
                return self._slowdns_info(actor)
            if sub == "users" and len(parts) == 5 and parts[4] == "slowdns":
                if not V2_NAME_RE.match(parts[3]):
                    return self.send_json(400, {"error": "Invalid account name"})
                if parts[3] not in mine:
                    return self.send_json(404, {"error": "Account not found"})
                return self._slowdns_config(actor, all_users[parts[3]], parts[3], qs)
            if sub == "online":
                om = v2_online_map()
                return self.send_json(200, {"online": {n: v for n, v in om.items() if n in mine}})
            if sub == "clientopts":
                if not self._v2_manager_has(mod, "cmd_clientopts"):
                    return
                st = mod.load_settings()
                return self.send_json(200, {"address": st.get("cfg_address", ""), "sni": st.get("cfg_sni", ""),
                                            "host": st.get("cfg_host", ""), "domain": st.get("domain", ""),
                                            "fake_site": st.get("fake_site", "")})
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

    def _v2_manager_has(self, mod, feature):
        """True when the installed V2Ray manager knows `feature`; else sends a clear 409."""
        if hasattr(mod, feature):
            return True
        self.send_json(409, {"error": "The V2Ray manager on this server is old and does not support this yet. "
                                      "Open the menu once (it refreshes the manager), then restart the panel: "
                                      "systemctl restart visibleTech-panel"})
        return False

    def _v2_conn_ok(self, actor, conn):
        """Reseller per-account connection cap for V2Ray (0/unlimited is refused when a cap is set)."""
        if actor[0] == "admin":
            return True
        err = reseller_conn_error(actor[1], conn)
        if err:
            self.send_json(403, {"error": err})
            return False
        return True

    def _slowdns_info(self, actor):
        if not slowdns_allowed(actor):
            return self.send_json(403, {"error": "SlowDNS access is not enabled for your account"})
        is_admin = actor[0] == "admin"
        tunnels = slowdns_tunnels(check_running=is_admin)
        if not is_admin:     # resellers only need the NS domains that already forward to V2Ray
            tunnels = [{"domain": t["domain"], "target": t["target"]} for t in tunnels if t["target"] in SLOWDNS_PORTS]
        return self.send_json(200, {"is_admin": is_admin, "installed": os.path.isfile(FASTDNS_MAIN_UNIT),
                                    "settings": slowdns_load(), "pubkey": slowdns_pubkey(), "tunnels": tunnels,
                                    "can_switch": os.path.isfile(FASTDNS_MODED)})

    def _slowdns_config(self, actor, u, name, qs):
        if not slowdns_allowed(actor):
            return self.send_json(403, {"error": "SlowDNS access is not enabled for your account"})
        cfg = slowdns_load()
        q = lambda k: (qs.get(k, [""])[0] or "").strip()
        try:
            ns = slowdns_norm_ns(q("ns")) or slowdns_norm_ns(cfg.get("ns"))
            if not ns:
                main = next((t["domain"] for t in slowdns_tunnels() if t["main"]), "")
                ns = main
            if not ns:
                return self.send_json(409, {"error": "No NS domain yet. Install FastDns from the menu, or set one in V2Ray > SlowDNS."})
            resolver = slowdns_resolve(q("resolver")) or cfg.get("resolver") or ""
            if not resolver:
                return self.send_json(409, {"error": "No DNS resolver set. Enter one here, or set a default in V2Ray > SlowDNS."})
            port = slowdns_norm_port(q("port"), slowdns_norm_port(cfg.get("port")))
        except ValueError as e:
            return self.send_json(400, {"error": str(e)})
        proto = u.get("proto")
        if proto not in SLOWDNS_PORTS:
            return self.send_json(400, {"error": "Unsupported protocol"})
        return self.send_json(200, {
            "config": slowdns_build_config(proto, u["id"], ns, resolver, port),
            "filename": "slowdns-v2ray-%s.json" % name,
            "ns": ns, "resolver": resolver, "port": port, "proto": proto,
            "pubkey": slowdns_pubkey(),
            "warning": slowdns_warning(ns, proto, actor[0] == "admin")})

    def _slowdns_save_settings(self, body):
        try:
            ns = slowdns_norm_ns(body.get("ns"))
            raw = str(body.get("resolver") or "").strip()
            ip = slowdns_resolve(raw)
            port = slowdns_norm_port(body.get("port"))
        except ValueError as e:
            return self.send_json(400, {"error": str(e)})
        cfg = {"ns": ns, "resolver": ip, "resolver_name": "" if raw == ip else raw, "port": port}
        try:
            slowdns_save(cfg)
        except OSError as e:
            return self.send_json(500, {"error": "Could not save: %s" % e})
        return self.send_json(200, {"success": True, "settings": cfg})

    def _slowdns_set_target(self, body):
        target = str(body.get("target", "")).strip().lower()
        domain = str(body.get("domain", "")).strip().lower()
        if target not in ("ssh",) + tuple(SLOWDNS_PORTS):
            return self.send_json(400, {"error": "Target must be SSH, VMess, VLess or Trojan"})
        if domain not in [t["domain"] for t in slowdns_tunnels()]:
            return self.send_json(404, {"error": "Unknown tunnel domain"})
        try:
            with open(FASTDNS_MODED, "rb") as f:
                has_feature = b"--set-target" in f.read()
        except OSError:
            has_feature = False
        if not has_feature:
            return self.send_json(409, {"error": "The FastDns script on this server is old. Open the menu once "
                                                 "(DNSTT, option 9) so it refreshes, then try again."})
        try:
            res = subprocess.run(["bash", FASTDNS_MODED, "--set-target", target, domain],
                                 capture_output=True, text=True, timeout=60)
        except Exception as e:
            return self.send_json(500, {"error": str(e)})
        text = re.sub(r'\x1b\[[0-9;]*m', '', (res.stdout or "") + "\n" + (res.stderr or ""))
        lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
        if res.returncode != 0:
            return self.send_json(400, {"error": (lines[-1] if lines else "Failed").lstrip("\u274c ").strip()})
        return self.send_json(200, {"success": True, "message": " ".join(lines[:2]) or "Updated",
                                    "tunnels": slowdns_tunnels(check_running=True)})

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
                if str(body.get("custom_id") or "").strip() and not self._v2_manager_has(mod, "ID_RE"):
                    return
                return self._v2_run(["add", "--proto", proto, "--name", name, "--days", v2_fmt(days),
                                     "--total", v2_fmt(v2_num(body.get("total_gb"))),
                                     "--daily", v2_fmt(v2_num(body.get("daily_gb"))),
                                     "--conn", str(conn), "--owner", owner]
                                    + (["--id", str(body.get("custom_id")).strip()] if str(body.get("custom_id") or "").strip() else []),
                                    mod, name)
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
                if str(body.get("custom_id") or "").strip() and not self._v2_manager_has(mod, "ID_RE"):
                    return
                return self._v2_run(["add", "--proto", proto, "--name", name, "--hours", v2_fmt(hours),
                                     "--total", v2_fmt(v2_num(body.get("total_gb"))), "--trial",
                                     "--conn", str(conn), "--owner", owner]
                                    + (["--id", str(body.get("custom_id")).strip()] if str(body.get("custom_id") or "").strip() else []),
                                    mod, name)
            if path == "/api/v2ray/clientopts":
                if actor[0] != "admin":
                    return self.send_json(403, {"error": "Admin access required"})
                if not self._v2_manager_has(mod, "cmd_clientopts"):
                    return
                args = ["clientopts"]
                if body.get("reset"):
                    args.append("--reset")
                for key in ("address", "sni", "host"):
                    if key in body:
                        args += ["--" + key, str(body.get(key) or "").strip()]
                code, out, err = v2_cli(args)
                if code != 0:
                    return self.send_json(400, {"error": (err or out or "Failed").replace("Error: ", "").strip()})
                try:
                    data = json.loads(out)
                except Exception:
                    data = {}
                return self.send_json(200, dict(data, success=True))
            if path == "/api/v2ray/fakesite":
                if actor[0] != "admin":
                    return self.send_json(403, {"error": "Admin access required"})
                if not self._v2_manager_has(mod, "cmd_fakesite"):
                    return
                tpl = str(body.get("template") or "").strip()
                if body.get("off") or not tpl:
                    args = ["fakesite", "--off"]
                elif tpl in ("business", "cloud", "blog"):
                    args = ["fakesite", "--template", tpl]
                else:
                    return self.send_json(400, {"error": "Unknown template"})
                code, out, err = v2_cli(args)
                if code != 0:
                    return self.send_json(400, {"error": (err or out or "Failed").replace("Error: ", "").strip()})
                try:
                    data = json.loads(out)
                except Exception:
                    data = {}
                return self.send_json(200, dict(data, success=True))
            if path in ("/api/v2ray/slowdns/settings", "/api/v2ray/slowdns/target"):
                if actor[0] != "admin":
                    return self.send_json(403, {"error": "Admin access required"})
                if path.endswith("/settings"):
                    return self._slowdns_save_settings(body)
                return self._slowdns_set_target(body)
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
                if action == "expiry":
                    # set the exact expiry date/time (epoch seconds), or 0 = never (admin only)
                    if body.get("from_today") not in (None, ""):
                        # expiry = now + N days (N counted from today, not from the old expiry)
                        days_ft = v2_num(body.get("from_today"), 30, 0, 3650)
                        ts = int(time.time() + days_ft * 86400)
                    elif body.get("never"):
                        if actor[0] != "admin":
                            return self.send_json(403, {"error": "Only the admin can remove the expiry date"})
                        ts = 0
                    else:
                        try:
                            ts = int(float(body.get("expiry")))
                        except (TypeError, ValueError):
                            return self.send_json(400, {"error": "Choose a valid expiry date"})
                        if ts < 946684800 or ts > int(time.time()) + 20 * 365 * 86400:
                            return self.send_json(400, {"error": "Expiry date is out of range"})
                    code, out, err = v2_set_expiry(name, ts)
                    if code != 0:
                        print("V2Ray expiry error (%s): code=%s out=%s err=%s" % (name, code, out, err), file=sys.stderr)
                        return self.send_json(400, {"error": (err or out or "Could not change the expiry").replace("Error: ", "").strip()})
                    d = self._v2_detail(mod, name)
                    return self.send_json(200, dict(d or {}, success=True))
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

    # ================= BACKUP / JOBS / REINSTALL / PROTOCOL CONTROL (admin only) =================
    def handle_backup_list(self):
        try:
            d = backup_dir()
            items = backup_list()
        except OSError as e:
            return self.send_json(500, {"error": "Cannot use the backup folder: %s" % e})
        s = backup_settings_load()
        self.send_json(200, {"dir": d, "keep": s["keep"], "default_dir": DEFAULT_BACKUP_DIR, "backups": items})

    def handle_backup_create(self):
        try:
            info = backup_create()
        except Exception as e:
            return self.send_json(500, {"error": "Backup failed: %s" % e})
        self.send_json(200, dict(info, success=True))

    def handle_backup_download(self, qs):
        name = qs.get("name", [""])[0]
        path = backup_path(name)
        if not path:
            return self.send_json(404, {"error": "Backup not found"})
        size = os.path.getsize(path)
        try:
            self.send_response(200)
            self.send_header("Content-Type", "application/gzip")
            self.send_header("Content-Disposition", 'attachment; filename="%s"' % name)
            self.send_header("Content-Length", str(size))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            sent = 0
            with open(path, "rb") as f:
                while True:
                    chunk = f.read(262144)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    sent += len(chunk)
            if sent == size:
                BACKUP_DOWNLOADED[name] = time.time()
        except (BrokenPipeError, ConnectionResetError):
            pass

    def handle_backup_delete(self, body):
        path = backup_path(body.get("name"))
        if not path:
            return self.send_json(404, {"error": "Backup not found"})
        try:
            os.remove(path)
        except OSError as e:
            return self.send_json(500, {"error": str(e)})
        BACKUP_DOWNLOADED.pop(os.path.basename(path), None)
        self.send_json(200, {"success": True})

    def handle_backup_settings(self, body):
        try:
            d = backup_clean_dir(body.get("dir") or DEFAULT_BACKUP_DIR)
            keep = int(body.get("keep", 10))
            if keep < 1 or keep > 200:
                raise ValueError("Keep between 1 and 200 backups")
            os.makedirs(d, mode=0o700, exist_ok=True)
            if not os.access(d, os.W_OK):
                raise ValueError("The panel cannot write to that folder")
        except (ValueError, TypeError, OSError) as e:
            return self.send_json(400, {"error": str(e) or "Invalid value"})
        backup_settings_save({"dir": d, "keep": keep})
        self.send_json(200, {"success": True, "dir": d, "keep": keep})

    def handle_backup_upload(self, qs, length):
        if length <= 0 or length > BACKUP_MAX_UPLOAD:
            return self.send_json(400, {"error": "Choose a backup file (max 1 GB)"})
        name = re.sub(r'[^A-Za-z0-9._-]', '_', qs.get("name", [""])[0])[:100]
        if not BACKUP_NAME_RE.match(name):
            name = "visibleTech_users_uploaded-%s.tar.gz" % time.strftime("%Y%m%d-%H%M%S")
        bdir = backup_dir()
        dest = os.path.join(bdir, name)
        if os.path.exists(dest):
            dest = os.path.join(bdir, name[:-7] + "-uploaded-%s.tar.gz" % time.strftime("%H%M%S"))
        tmp = dest + ".part"
        remaining = length
        with open(tmp, "wb") as f:
            while remaining > 0:
                chunk = self.rfile.read(min(262144, remaining))
                if not chunk:
                    break
                f.write(chunk)
                remaining -= len(chunk)
        if remaining:
            os.remove(tmp)
            return self.send_json(400, {"error": "Upload was interrupted - try again"})
        try:
            backup_validate(tmp)
        except ValueError as e:
            os.remove(tmp)
            return self.send_json(400, {"error": str(e)})
        os.chmod(tmp, 0o600)
        os.replace(tmp, dest)
        self.send_json(200, dict(backup_info(dest), success=True))

    def handle_backup_restore(self, body):
        name = body.get("name")
        path = backup_path(name)
        if not path:
            return self.send_json(404, {"error": "Backup not found"})
        try:
            backup_validate(path)
        except ValueError as e:
            return self.send_json(400, {"error": str(e)})
        opts = {"panel_login": bool(body.get("panel_login", False))}
        try:
            jid = job_start("restore", "Restore " + os.path.basename(path), lambda log: backup_restore(path, opts, log))
        except ValueError as e:
            return self.send_json(409, {"error": str(e)})
        self.send_json(200, {"success": True, "job": jid})

    def handle_job_get(self, job_id, qs):
        job = JOBS.get(job_id)
        if not job:
            return self.send_json(404, {"error": "Task not found"})
        try:
            since = max(0, int(qs.get("since", ["0"])[0]))
        except ValueError:
            since = 0
        self.send_json(200, job_public(job, since))

    def handle_jobs_list(self):
        with jobs_lock:
            items = sorted(JOBS.values(), key=lambda x: x["started"], reverse=True)[:5]
            out = [{"id": j["id"], "title": j["title"], "status": j["status"], "kind": j["kind"]} for j in items]
        self.send_json(200, {"jobs": out})

    def handle_reinstall_options(self):
        self.send_json(200, reinstall_catalog())

    def handle_reinstall(self, body):
        try:
            args, label, destructive, reboots = reinstall_build(body)
        except ValueError as e:
            return self.send_json(400, {"error": str(e)})
        cmd_preview = "./reinstall.sh " + reinstall_mask(args)
        if body.get("preview"):
            return self.send_json(200, {"success": True, "label": label, "destructive": destructive, "command": cmd_preview})
        if destructive:
            if body.get("confirm") != "REINSTALL":
                return self.send_json(400, {"error": "Type REINSTALL to confirm"})
            if not body.get("skip_backup"):
                bname = str(body.get("backup_name", ""))
                if not backup_path(bname) or bname not in BACKUP_DOWNLOADED:
                    return self.send_json(400, {"error": "Create a backup and download it to your device first (or tick 'skip backup')"})
        # what to tell the user at the end
        ip = reinstall_sysinfo().get("ip") or "SERVER-IP"
        mode = str(body.get("mode", "linux")).lower()
        user = str(body.get("username") or "").strip()
        if mode == "windows":
            port = str(body.get("rdp_port") or "").strip() or "3389"
            note = "Connect with Remote Desktop to %s:%s as %s with the password you typed." % (ip, port, user or "administrator")
        elif mode in ("netboot", "live") or mode == "dd":
            port = str(body.get("ssh_port") or "").strip() or "22"
            note = "Use your provider console (VNC) for netboot.xyz." if mode == "netboot" else \
                "Sign in: ssh -p %s %s@%s  (the password you typed, if you set one)" % (port, user or "root", ip)
        else:
            port = str(body.get("ssh_port") or "").strip() or "22"
            note = "Sign in: ssh -p %s %s@%s  (the password you typed)" % (port, user or "root", ip)
        try:
            jid = job_start("reinstall", "Reinstall: " + label,
                            lambda log: reinstall_run(args, label, reboots, note, log))
        except ValueError as e:
            return self.send_json(409, {"error": str(e)})
        self.send_json(200, {"success": True, "job": jid})

    def handle_protocol_action(self, service, action):
        p = proto_find(service)
        if not p or action not in PROTO_ACTIONS:
            return self.send_json(404, {"error": "Unknown service or action"})
        if service in ("sshd", "ssh") and action in ("stop", "disable"):
            return self.send_json(400, {"error": "Stopping SSH would lock you out of the server"})
        if p.get("check_file") and not os.path.exists(p["check_file"]):
            return self.send_json(409, {"error": "%s is not installed" % p["name"]})
        units = [service] + ([p["service_alt"]] if p.get("service_alt") else [])
        err = ""
        for unit in units:
            code, _, err = run_cmd(["systemctl", action, unit], ignore_errors=True)
            if code == 0:
                return self.send_json(200, {"success": True})
        self.send_json(500, {"success": False, "error": err or "systemctl failed"})

    def handle_protocol_install(self, service, action):
        p = proto_find(service)
        if not p or service in ("sshd", "ssh") or action not in ("install", "uninstall"):
            return self.send_json(404, {"error": "Unknown service or action"})
        cmd = proto_installer(service, action)
        if not cmd:
            return self.send_json(409, {"error": "This server has no installer for %s yet. "
                                                 "Add one in %s or update the menu script." % (p["name"], PROTO_INSTALLERS_FILE)})
        try:
            jid = job_start("protocol", "%s %s" % (action.title(), p["name"]), lambda log: _run_installer(cmd, log))
        except ValueError as e:
            return self.send_json(409, {"error": str(e)})
        self.send_json(200, {"success": True, "job": jid})

    def handle_pwa(self, name, base):
        creds = get_panel_creds()
        pname = (creds.get("PANEL_NAME") or "visibleTech Panel").strip() or "visibleTech Panel"
        headers = {"Cache-Control": "no-cache"}
        if name == "manifest.webmanifest":
            ctype = "application/manifest+json"
            data = json.dumps({
                "id": base, "name": pname, "short_name": pname[:12], "description": "Server control panel",
                "start_url": base, "scope": base, "display": "standalone",
                "background_color": "#0a0e22", "theme_color": "#0a0e22",
                "icons": [
                    {"src": base + "icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any"},
                    {"src": base + "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any"},
                    {"src": base + "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable"}]
            }).encode()
        elif name == "sw.js":
            ctype = "application/javascript; charset=utf-8"
            data = PWA_SW_JS.encode()
            headers["Service-Worker-Allowed"] = base
        else:
            import base64
            ctype = "image/png"
            data = base64.b64decode(PWA_ICON_192_B64 if "192" in name else PWA_ICON_512_B64)
            headers["Cache-Control"] = "public, max-age=86400"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        for k, v in headers.items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)


def main():
    os.makedirs(os.path.dirname(DB_FILE), exist_ok=True)
    seed_default_creds()
    server_address = ('0.0.0.0', PORT)
    httpd = ThreadingHTTPServer(server_address, PanelAPIHandler)
    scheme = "http"
    if os.environ.get("PANEL_HTTPS") == "1":            # optional: serve the panel over HTTPS (needed to install it as an app)
        cert = os.environ.get("PANEL_CERT", DB_DIR + "/ssl/visibleTech.crt")
        key = os.environ.get("PANEL_KEY", DB_DIR + "/ssl/visibleTech.key")
        try:
            import ssl
            ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            ctx.minimum_version = ssl.TLSVersion.TLSv1_2
            ctx.load_cert_chain(cert, key)
            httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True, do_handshake_on_connect=False)
            scheme = "https"
        except Exception as e:
            print(f"HTTPS requested but not enabled ({e}); serving plain HTTP instead.", file=sys.stderr, flush=True)
    print(f"Starting {scheme} server on port {PORT} (data dir {DB_DIR}, html {PANEL_HTML}, html exists: {os.path.exists(PANEL_HTML)}, conf exists: {os.path.exists(PANEL_CONF)})", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    print("Server stopped.")

if __name__ == '__main__':
    main()
