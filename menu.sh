#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_UL=$'\033[4m'

# Premium Color Palette
C_RED=$'\033[38;5;196m'      # Bright Red
C_GREEN=$'\033[38;5;46m'     # Neon Green
C_YELLOW=$'\033[38;5;226m'   # Bright Yellow
C_BLUE=$'\033[38;5;39m'      # Deep Sky Blue
C_PURPLE=$'\033[38;5;135m'   # Light Purple
C_CYAN=$'\033[38;5;51m'      # Cyan
C_WHITE=$'\033[38;5;255m'    # Bright White
C_GRAY=$'\033[38;5;245m'     # Gray
C_ORANGE=$'\033[38;5;208m'   # Orange

# Semantic Aliases
C_TITLE=$C_PURPLE
C_CHOICE=$C_CYAN
C_PROMPT=$C_BLUE
C_WARN=$C_YELLOW
C_DANGER=$C_RED
C_STATUS_A=$C_GREEN
C_STATUS_I=$C_GRAY
C_ACCENT=$C_ORANGE

DB_DIR="/etc/visibleTech"
DB_FILE="$DB_DIR/users.db"
INSTALL_FLAG_FILE="$DB_DIR/.install"
BADVPN_SERVICE_FILE="/etc/systemd/system/badvpn.service"
BADVPN_BUILD_DIR="/root/badvpn-build"
SSL_CERT_DIR="/etc/visibleTech/ssl"
SSL_CERT_CHAIN_FILE="$SSL_CERT_DIR/visibleTech.crt"
SSL_CERT_KEY_FILE="$SSL_CERT_DIR/visibleTech.key"

# --- WebSocket Proxy & Stunnel Variables ---
WS_SCRIPT="/usr/local/bin/visibleTech-ws.py"
WS_SERVICE_NAME="visibleTech-ws"
WS_SERVICE_FILE="/etc/systemd/system/visibleTech-ws.service"
WS_CONFIG_FILE="$DB_DIR/websocket_config.conf"
STUNNEL_DIR="$DB_DIR/stunnel"
STUNNEL_CONF="$STUNNEL_DIR/stunnel.conf"
STUNNEL_SERVICE_NAME="visibleTech-stunnel"
STUNNEL_SERVICE_FILE="/etc/systemd/system/visibleTech-stunnel.service"
STUNNEL_INFO_FILE="$DB_DIR/stunnel_info.conf"
STUNNEL_RENEW_HOOK="/etc/letsencrypt/renewal-hooks/deploy/visibleTech-stunnel.sh"
DNSTT_SERVICE_FILE="/etc/systemd/system/dnstt.service"
DNSTT_BINARY="/usr/local/bin/dnstt-server"
DNSTT_KEYS_DIR="/etc/visibleTech/dnstt"
DNSTT_CONFIG_FILE="$DB_DIR/dnstt_info.conf"
# FastDns Moded (DNSTT + EDNS proxy)
FASTDNS_MODED_DIR="/usr/local/lib/visibleTech-fastdns"
FASTDNS_MODED_SCRIPT="$FASTDNS_MODED_DIR/moded.sh"
FASTDNS_DIR="/etc/fastdns"
FASTDNS_SERVICE_FILE="/etc/systemd/system/server-sldns.service"
FASTDNS_EDNS_SERVICE_FILE="/etc/systemd/system/edns-proxy.service"
FASTDNS_TUNNELS_FILE="$FASTDNS_DIR/tunnels.conf"
FASTDNS_KEYS_PUB="$FASTDNS_DIR/server.pub"
# V2Ray (Xray): VMess / VLESS / Trojan over WS + gRPC
V2_DIR="$DB_DIR/v2ray"
V2_LIB_DIR="/usr/local/lib/visibleTech-v2ray"
V2_MANAGER="$V2_LIB_DIR/ffv2ray.py"
V2_XRAY_BIN="$V2_LIB_DIR/xray"
V2_REPO_BASE="https://raw.githubusercontent.com/wavy07/manage/main/V2RAY%20MODED"
V2_XRAY_SERVICE="ff-xray"
V2_NGINX_SERVICE="ff-v2ray-nginx"
V2_LIMITER_SERVICE="ff-v2ray-limiter"
V2_XRAY_SERVICE_FILE="/etc/systemd/system/ff-xray.service"
V2_NGINX_SERVICE_FILE="/etc/systemd/system/ff-v2ray-nginx.service"
V2_LIMITER_SERVICE_FILE="/etc/systemd/system/ff-v2ray-limiter.service"
DNS_INFO_FILE="$DB_DIR/dns_info.conf"
UDP_CUSTOM_DIR="/root/udp"
UDP_CUSTOM_SERVICE_FILE="/etc/systemd/system/udp-custom.service"
UDPGW_BINARY="/usr/local/bin/udpgw"
UDPGW_SERVICE_FILE="/etc/systemd/system/udpgw.service"
SSH_BANNER_FILE="/etc/bannerssh"
LIMITER_SCRIPT="/usr/local/bin/visibleTech-limiter.sh"
LIMITER_SERVICE="/etc/systemd/system/visibleTech-limiter.service"
BANDWIDTH_DIR="$DB_DIR/bandwidth"
BANDWIDTH_SCRIPT="/usr/local/bin/visibleTech-bandwidth.sh"
BANDWIDTH_SERVICE="/etc/systemd/system/visibleTech-bandwidth.service"
LEGACY_BANDWIDTH_DIR="/usr/local/bin/visibleTech-bandwidth"
TRIAL_CLEANUP_SCRIPT="/usr/local/bin/visibleTech-trial-cleanup.sh"
LOGIN_INFO_SCRIPT="/usr/local/bin/visibleTech-login-info.sh"
SSHD_FF_CONFIG="/etc/ssh/sshd_config.d/visibleTech.conf"

# --- Web Panel Variables ---
PANEL_SCRIPT="/usr/local/bin/visibleTech-panel.py"
PANEL_HTML_DIR="$DB_DIR/panel"
PANEL_HTML_FILE="$DB_DIR/panel/index.html"
PANEL_CONF="$DB_DIR/panel.conf"
PANEL_SERVICE_FILE="/etc/systemd/system/visibleTech-panel.service"
PANEL_PORT=44380
PANEL_REPO_BASE="https://github.com/wavy07/manage/raw/main/panel"

# --- ZiVPN Variables ---
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
ZIVPN_SERVICE_FILE="/etc/systemd/system/zivpn.service"
ZIVPN_CONFIG_FILE="$ZIVPN_DIR/config.json"
ZIVPN_CERT_FILE="$ZIVPN_DIR/zivpn.crt"
ZIVPN_KEY_FILE="$ZIVPN_DIR/zivpn.key"

DESEC_TOKEN="V55cFY8zTictLCPfviiuX5DHjs15"
DESEC_DOMAIN="manager.visibleTech.qzz.io"

SELECTED_USER=""
UNINSTALL_MODE="interactive"
BANNER_CACHE_TTL=15
BANNER_CACHE_TS=0
BANNER_CACHE_OS_NAME=""
BANNER_CACHE_UP_TIME=""
BANNER_CACHE_RAM_USAGE=""
BANNER_CACHE_CPU_LOAD=""
BANNER_CACHE_ONLINE_USERS=0
BANNER_CACHE_TOTAL_USERS=0
SSH_SESSION_CACHE_TTL=10
SSH_SESSION_CACHE_TS=0
SSH_SESSION_CACHE_DB_MTIME=0
SSH_SESSION_TOTAL=0
APT_CACHE_READY=0
FF_USERS_GROUP="ffusers"
declare -A SSH_SESSION_COUNTS=()
declare -A SSH_SESSION_PIDS=()

# --- Package Manager Abstraction ---
FF_PKG_MGR=""
_detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        FF_PKG_MGR="apt"
    elif command -v dnf &>/dev/null; then
        FF_PKG_MGR="dnf"
    elif command -v yum &>/dev/null; then
        FF_PKG_MGR="yum"
    elif command -v zypper &>/dev/null; then
        FF_PKG_MGR="zypper"
    elif command -v pacman &>/dev/null; then
        FF_PKG_MGR="pacman"
    else
        echo -e "${C_RED}❌ No supported package manager found (apt/dnf/yum/zypper/pacman).${C_RESET}"
        exit 1
    fi
}
_detect_pkg_manager

_map_pkg_names() {
    local -a result=()
    local pkg
    for pkg in "$@"; do
        case "$FF_PKG_MGR" in
            dnf|yum)
                case "$pkg" in
                    build-essential) result+=(gcc gcc-c++ make) ;;
                    libssl-dev) result+=(openssl-devel) ;;
                    libnspr4-dev) result+=(nspr-devel) ;;
                    libnss3-dev) result+=(nss-devel) ;;
                    stunnel4) result+=(stunnel) ;;
                    pkg-config) result+=(pkgconf) ;;
                    *) result+=("$pkg") ;;
                esac ;;
            zypper)
                case "$pkg" in
                    build-essential) result+=(gcc gcc-c++ make) ;;
                    libssl-dev) result+=(libopenssl-devel) ;;
                    libnspr4-dev) result+=(mozilla-nspr-devel) ;;
                    libnss3-dev) result+=(mozilla-nss-devel) ;;
                    stunnel4) result+=(stunnel) ;;
                    *) result+=("$pkg") ;;
                esac ;;
            pacman)
                case "$pkg" in
                    build-essential) result+=(base-devel) ;;
                    libssl-dev) result+=(openssl) ;;
                    libnspr4-dev) result+=(nspr) ;;
                    libnss3-dev) result+=(nss) ;;
                    stunnel4) result+=(stunnel) ;;
                    bc) result+=(bc) ;;
                    *) result+=("$pkg") ;;
                esac ;;
            *) result+=("$pkg") ;;
        esac
    done
    printf '%s\n' "${result[@]}"
}

if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}❌ Error: This script requires root privileges to run.${C_RESET}"
   exit 1
fi

get_ubuntu_codename() {
    local codename=""

    if [[ -r /etc/os-release ]]; then
        codename=$(awk -F= '/^(VERSION_CODENAME|UBUNTU_CODENAME)=/{gsub(/"/, "", $2); if ($2 != "") { print $2; exit }}' /etc/os-release 2>/dev/null)
    fi

    if [[ -z "$codename" ]] && command -v lsb_release &>/dev/null; then
        codename=$(lsb_release -sc 2>/dev/null)
    fi

    echo "$codename"
}

is_known_eol_ubuntu_codename() {
    case "$1" in
        yakkety|zesty|artful|cosmic|disco|eoan|groovy|hirsute|impish|kinetic|lunar|mantic|oracular|plucky)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

rewrite_ubuntu_apt_sources() {
    local mode="$1"
    local os_id=""
    local changed=false
    local file backup_file
    local from_archive to_archive from_security to_security from_ports to_ports
    local -a source_files=("/etc/apt/sources.list" /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources)

    if [[ -r /etc/os-release ]]; then
        os_id=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2; exit}' /etc/os-release 2>/dev/null)
    fi
    [[ "$os_id" == "ubuntu" ]] || return 1

    case "$mode" in
        primary)
            from_archive='https?://([A-Za-z0-9-]+\.)?archive\.ubuntu\.com/ubuntu'
            to_archive='http://archive.ubuntu.com/ubuntu'
            from_security='https?://security\.ubuntu\.com/ubuntu'
            to_security='http://security.ubuntu.com/ubuntu'
            from_ports='https?://ports\.ubuntu\.com/ubuntu-ports'
            to_ports='http://ports.ubuntu.com/ubuntu-ports'
            ;;
        old-releases)
            from_archive='https?://([A-Za-z0-9-]+\.)?archive\.ubuntu\.com/ubuntu'
            to_archive='http://old-releases.ubuntu.com/ubuntu'
            from_security='https?://security\.ubuntu\.com/ubuntu'
            to_security='http://old-releases.ubuntu.com/ubuntu'
            from_ports='https?://ports\.ubuntu\.com/ubuntu-ports'
            to_ports='http://old-releases.ubuntu.com/ubuntu'
            ;;
        *)
            return 1
            ;;
    esac

    for file in "${source_files[@]}"; do
        [[ -f "$file" ]] || continue
        if grep -Eq "$from_archive|$from_security|$from_ports" "$file" 2>/dev/null; then
            backup_file="${file}.bak.visibleTech"
            [[ -f "$backup_file" ]] || cp "$file" "$backup_file" 2>/dev/null || true
            sed -i -E \
                -e "s|$from_archive|$to_archive|g" \
                -e "s|$from_security|$to_security|g" \
                -e "s|$from_ports|$to_ports|g" \
                "$file" 2>/dev/null
            changed=true
        fi
    done

    $changed
}

repair_ubuntu_apt_mirrors() {
    rewrite_ubuntu_apt_sources "primary"
}

switch_ubuntu_to_old_releases() {
    local codename
    codename=$(get_ubuntu_codename)
    [[ -n "$codename" ]] || return 1
    is_known_eol_ubuntu_codename "$codename" || return 1
    rewrite_ubuntu_apt_sources "old-releases"
}

ff_apt_update() {
    local -a apt_opts=(
        -o Acquire::Retries=3
        -o Acquire::ForceIPv4=true
        -o Acquire::http::Timeout=20
        -o Acquire::https::Timeout=20
        -o Acquire::http::Pipeline-Depth=0
    )

    if (( APT_CACHE_READY == 1 )); then
        return 0
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
        APT_CACHE_READY=1
        return 0
    fi

    if repair_ubuntu_apt_mirrors; then
        echo -e "${C_YELLOW}⚠️ APT mirror timed out. Switching Ubuntu sources to archive.ubuntu.com and retrying...${C_RESET}"
        apt-get clean >/dev/null 2>&1 || true
        if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
            APT_CACHE_READY=1
            return 0
        fi
    fi

    if switch_ubuntu_to_old_releases; then
        echo -e "${C_YELLOW}⚠️ Detected an end-of-life Ubuntu release. Switching APT sources to old-releases.ubuntu.com and retrying...${C_RESET}"
        apt-get clean >/dev/null 2>&1 || true
        if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
            APT_CACHE_READY=1
            return 0
        fi
    fi

    echo -e "${C_RED}❌ Failed to refresh package lists. Please check VPS network, DNS, or blocked Ubuntu mirrors.${C_RESET}"
    return 1
}

ff_apt_install() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0

    ff_apt_update || return 1
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 install "${packages[@]}"
}

ff_apt_purge() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 purge "${packages[@]}"
}

ff_pkg_install() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0
    local -a mapped=()
    mapfile -t mapped < <(_map_pkg_names "${packages[@]}")
    case "$FF_PKG_MGR" in
        apt) ff_apt_install "${mapped[@]}" ;;
        dnf) dnf install -y -q "${mapped[@]}" ;;
        yum) yum install -y -q "${mapped[@]}" ;;
        zypper) zypper install -y -q "${mapped[@]}" ;;
        pacman) pacman -S --noconfirm --needed "${mapped[@]}" ;;
        *) echo -e "${C_RED}❌ Unsupported package manager.${C_RESET}"; return 1 ;;
    esac
}

ff_pkg_purge() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0
    local -a mapped=()
    mapfile -t mapped < <(_map_pkg_names "${packages[@]}")
    case "$FF_PKG_MGR" in
        apt) ff_apt_purge "${mapped[@]}" ;;
        dnf) dnf remove -y -q "${mapped[@]}" ;;
        yum) yum remove -y -q "${mapped[@]}" ;;
        zypper) zypper remove -y "${mapped[@]}" ;;
        pacman) pacman -Rns --noconfirm "${mapped[@]}" 2>/dev/null ;;
        *) echo -e "${C_RED}❌ Unsupported package manager.${C_RESET}"; return 1 ;;
    esac
}

ff_pkg_autoremove() {
    case "$FF_PKG_MGR" in
        apt) apt-get autoremove -y >/dev/null 2>&1 ;;
        dnf) dnf autoremove -y -q >/dev/null 2>&1 ;;
        yum) yum autoremove -y -q >/dev/null 2>&1 ;;
        zypper) zypper packages --unneeded 2>/dev/null | awk -F'|' 'NR>3{print $3}' | xargs -r zypper remove -y >/dev/null 2>&1 ;;
        pacman) pacman -Qdtq 2>/dev/null | xargs -r pacman -Rns --noconfirm >/dev/null 2>&1 ;;
    esac
    return 0
}

ff_pkg_is_installed() {
    local pkg="$1"
    case "$FF_PKG_MGR" in
        apt) dpkg -s "$pkg" &>/dev/null ;;
        dnf|yum) rpm -q "$pkg" &>/dev/null ;;
        zypper) rpm -q "$pkg" &>/dev/null ;;
        pacman) pacman -Q "$pkg" &>/dev/null ;;
    esac
}

# Mandatory Dependency Check (Added jq and curl)
check_environment() {
    local missing_packages=()
    local cmd

    for cmd in bc jq curl wget; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_packages+=("$cmd")
        fi
    done

    if (( ${#missing_packages[@]} > 0 )); then
        echo -e "${C_YELLOW}⚠️ Installing missing dependencies: ${missing_packages[*]}${C_RESET}"
        ff_pkg_install "${missing_packages[@]}" >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Error: Failed to install required dependencies: ${missing_packages[*]}.${C_RESET}"
            exit 1
        }
    fi
}

ensure_visibleTech_dirs() {
    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$BANDWIDTH_DIR" /etc/ssh/sshd_config.d
    touch "$DB_FILE"
}

ensure_visibleTech_system_group() {
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1 || true
}

db_has_user() {
    [[ -f "$DB_FILE" ]] || return 1
    awk -F: -v target="$1" '$1 == target { found=1; exit } END { exit(found ? 0 : 1) }' "$DB_FILE"
}

is_visibleTech_orphan_user() {
    local username="$1"
    local passwd_line system_user _ uid _ home shell

    passwd_line=$(getent passwd "$username" 2>/dev/null) || return 1
    IFS=: read -r system_user _ uid _ _ home shell <<< "$passwd_line"
    [[ "$uid" =~ ^[0-9]+$ ]] || return 1
    db_has_user "$username" && return 1

    if id -nG "$username" 2>/dev/null | tr ' ' '\n' | grep -Fxq "$FF_USERS_GROUP"; then
        return 0
    fi

    (( uid >= 1000 )) || return 1
    [[ "$home" == "/home/$username" || "$home" == /home/* ]] || return 1

    case "$shell" in
        /usr/sbin/nologin|/usr/bin/false|/bin/false) return 0 ;;
    esac

    return 1
}

get_visibleTech_orphan_users() {
    local username
    while IFS=: read -r username _rest; do
        [[ -n "$username" ]] || continue
        if is_visibleTech_orphan_user "$username"; then
            echo "$username"
        fi
    done < /etc/passwd
}

get_visibleTech_known_users() {
    local username
    local -A seen_users=()

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r username _rest; do
            [[ -n "$username" && "$username" != \#* ]] || continue
            seen_users["$username"]=1
        done < "$DB_FILE"
    fi

    while IFS= read -r username; do
        [[ -n "$username" ]] && seen_users["$username"]=1
    done < <(get_visibleTech_orphan_users)

    (( ${#seen_users[@]} > 0 )) || return 0
    printf "%s\n" "${!seen_users[@]}" | sort
}

delete_visibleTech_user_accounts() {
    local -a users_to_delete=("$@")
    local username

    [[ ${#users_to_delete[@]} -gt 0 ]] || return 0

    for username in "${users_to_delete[@]}"; do
        [[ -n "$username" ]] || continue
        killall -u "$username" -9 &>/dev/null
        pkill -9 -u "$username" &>/dev/null
        sleep 0.5
        if id "$username" &>/dev/null; then
            if userdel -rf "$username" &>/dev/null; then
                echo -e " ✅ System user '${C_YELLOW}$username${C_RESET}' deleted."
            else
                # Retry after harder kill
                pkill -9 -u "$username" &>/dev/null
                sleep 1
                if userdel -rf "$username" &>/dev/null; then
                    echo -e " ✅ System user '${C_YELLOW}$username${C_RESET}' deleted (retry)."
                else
                    echo -e " ❌ Failed to delete system user '${C_YELLOW}$username${C_RESET}'."
                fi
            fi
        else
            echo -e " ℹ️ System user '${C_YELLOW}$username${C_RESET}' was already missing. Removing manager data only."
        fi
        rm -f "$BANDWIDTH_DIR/${username}.usage"
        rm -f "$BANDWIDTH_DIR/${username}.daily_usage"
        rm -f "$BANDWIDTH_DIR/${username}.conn_locked"
        rm -f "$BANDWIDTH_DIR/${username}.daily_locked"
        rm -rf "$BANDWIDTH_DIR/pidtrack/${username}"
    done

    if [[ -f "$DB_FILE" ]]; then
        local db_tmp
        db_tmp=$(mktemp)
        awk -F: 'NR==FNR { drop[$1]=1; next } !($1 in drop)' <(printf "%s\n" "${users_to_delete[@]}") "$DB_FILE" > "$db_tmp" && mv "$db_tmp" "$DB_FILE"
        rm -f "$db_tmp" 2>/dev/null
    fi

    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

require_interactive_terminal() {
    if [[ ! -t 0 || ! -t 1 ]]; then
        echo -e "${C_RED}❌ Error: The visibleTech menu must be run from an interactive terminal.${C_RESET}"
        exit 1
    fi
}

initial_setup() {
    echo -e "${C_BLUE}⚙️ Initializing visibleTech Manager setup...${C_RESET}"
    check_environment
    
    ensure_visibleTech_dirs
    ensure_visibleTech_system_group
    
    echo -e "${C_BLUE}🔹 Configuring user limiter service...${C_RESET}"
    setup_limiter_service
    
    echo -e "${C_BLUE}🔹 Configuring bandwidth monitoring service...${C_RESET}"
    setup_bandwidth_service
    
    echo -e "${C_BLUE}🔹 Installing trial account cleanup script...${C_RESET}"
    setup_trial_cleanup_script
    
    echo -e "${C_BLUE}🔹 Cleaning legacy dynamic SSH banner hooks...${C_RESET}"
    disable_dynamic_ssh_banner_system
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || true
    
    if [ ! -f "$INSTALL_FLAG_FILE" ]; then
        touch "$INSTALL_FLAG_FILE"
    fi
    echo -e "${C_GREEN}✅ Setup finished.${C_RESET}"
}

_is_valid_ipv4() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

check_and_open_firewall_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    local firewall_detected=false

    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        firewall_detected=true
        if ! ufw status | grep -qw "$port/$protocol"; then
            echo -e "${C_YELLOW}🔥 UFW firewall is active and port ${port}/${protocol} is closed.${C_RESET}"
            read -p "👉 Do you want to open this port now? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                ufw allow "$port/$protocol"
                echo -e "${C_GREEN}✅ Port ${port}/${protocol} has been opened in UFW.${C_RESET}"
            else
                echo -e "${C_RED}❌ Warning: Port ${port}/${protocol} was not opened. The service may not work correctly.${C_RESET}"
                return 1
            fi
        else
             echo -e "${C_GREEN}✅ Port ${port}/${protocol} is already open in UFW.${C_RESET}"
        fi
    fi

    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        firewall_detected=true
        if ! firewall-cmd --list-ports --permanent | grep -qw "$port/$protocol"; then
            echo -e "${C_YELLOW}🔥 firewalld is active and port ${port}/${protocol} is not open.${C_RESET}"
            read -p "👉 Do you want to open this port now? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                firewall-cmd --add-port="$port/$protocol" --permanent
                firewall-cmd --reload
                echo -e "${C_GREEN}✅ Port ${port}/${protocol} has been opened in firewalld.${C_RESET}"
            else
                echo -e "${C_RED}❌ Warning: Port ${port}/${protocol} was not opened. The service may not work correctly.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Port ${port}/${protocol} is already open in firewalld.${C_RESET}"
        fi
    fi

    if ! $firewall_detected; then
        echo -e "${C_BLUE}ℹ️ No active firewall (UFW or firewalld) detected. Assuming ports are open.${C_RESET}"
    fi
    return 0
}

check_and_open_firewall_port_range() {
    local port_range="$1"
    local protocol="${2:-tcp}"
    local firewall_detected=false

    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        firewall_detected=true
        if ! ufw status | grep -Fq "$port_range/$protocol"; then
            echo -e "${C_YELLOW}🔥 UFW firewall is active and range ${port_range}/${protocol} is closed.${C_RESET}"
            read -p "👉 Do you want to open this port range now? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                ufw allow "$port_range/$protocol"
                echo -e "${C_GREEN}✅ Range ${port_range}/${protocol} has been opened in UFW.${C_RESET}"
            else
                echo -e "${C_RED}❌ Warning: Range ${port_range}/${protocol} was not opened. The service may not work correctly.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Range ${port_range}/${protocol} is already open in UFW.${C_RESET}"
        fi
    fi

    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        firewall_detected=true
        if ! firewall-cmd --quiet --query-port="$port_range/$protocol"; then
            echo -e "${C_YELLOW}🔥 firewalld is active and range ${port_range}/${protocol} is not open.${C_RESET}"
            read -p "👉 Do you want to open this port range now? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                firewall-cmd --add-port="$port_range/$protocol" --permanent
                firewall-cmd --reload
                echo -e "${C_GREEN}✅ Range ${port_range}/${protocol} has been opened in firewalld.${C_RESET}"
            else
                echo -e "${C_RED}❌ Warning: Range ${port_range}/${protocol} was not opened. The service may not work correctly.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Range ${port_range}/${protocol} is already open in firewalld.${C_RESET}"
        fi
    fi

    if ! $firewall_detected; then
        echo -e "${C_BLUE}ℹ️ No active firewall (UFW or firewalld) detected. Assuming range ${port_range}/${protocol} is open.${C_RESET}"
    fi
    return 0
}

check_and_free_ports() {
    local ports_to_check=("$@")
    for port in "${ports_to_check[@]}"; do
        echo -e "\n${C_BLUE}🔎 Checking if port $port is available...${C_RESET}"
        local conflicting_process_info
        conflicting_process_info=$(
            ss -H -lntp "( sport = :$port )" 2>/dev/null
            ss -H -lunp "( sport = :$port )" 2>/dev/null
        )
        
        if [[ -n "$conflicting_process_info" ]]; then
            local conflicting_pid
            conflicting_pid=$(echo "$conflicting_process_info" | grep -oP 'pid=\K[0-9]+' | head -n 1)
            local conflicting_name
            conflicting_name=$(echo "$conflicting_process_info" | grep -oP 'users:\(\("(\K[^"]+)' | head -n 1)
            
            echo -e "${C_YELLOW}⚠️ Warning: Port $port is in use by process '${conflicting_name:-unknown}' (PID: ${conflicting_pid:-N/A}).${C_RESET}"
            read -p "👉 Do you want to attempt to stop this process? (y/n): " kill_confirm
            if [[ "$kill_confirm" == "y" || "$kill_confirm" == "Y" ]]; then
                if [[ -z "$conflicting_pid" ]]; then
                    echo -e "${C_RED}❌ Could not determine which PID owns port $port. Please free it manually.${C_RESET}"
                    return 1
                fi
                echo -e "${C_GREEN}🛑 Stopping process PID $conflicting_pid...${C_RESET}"
                systemctl stop "$(ps -p "$conflicting_pid" -o comm=)" &>/dev/null || kill -9 "$conflicting_pid"
                sleep 2
                
                if ss -H -lntp "( sport = :$port )" 2>/dev/null | grep -q . || ss -H -lunp "( sport = :$port )" 2>/dev/null | grep -q .; then
                     echo -e "${C_RED}❌ Failed to free port $port. Please handle it manually. Aborting.${C_RESET}"
                     return 1
                else
                     echo -e "${C_GREEN}✅ Port $port has been successfully freed.${C_RESET}"
                fi
            else
                echo -e "${C_RED}❌ Cannot proceed without freeing port $port. Aborting.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Port $port is free to use.${C_RESET}"
        fi
    done
    return 0
}

setup_limiter_service() {
    # Combined limiter + bandwidth monitoring
    cat > "$LIMITER_SCRIPT" << 'EOF'
#!/bin/bash
# visibleTech limiter version 2026-07-23.4
DB_FILE="/etc/visibleTech/users.db"
BW_DIR="/etc/visibleTech/bandwidth"
PID_DIR="$BW_DIR/pidtrack"
BANNER_DIR="/etc/visibleTech/banners"
SCAN_INTERVAL=10
CONN_LOCK_DURATION=60

mkdir -p "$BW_DIR" "$PID_DIR"
shopt -s nullglob

write_banner_if_changed() {
    local user="$1"
    local content="$2"
    local banner_file="$BANNER_DIR/${user}.txt"
    local tmp_file="${banner_file}.tmp"

    printf "%s" "$content" > "$tmp_file"
    if ! cmp -s "$tmp_file" "$banner_file" 2>/dev/null; then
        mv "$tmp_file" "$banner_file"
    else
        rm -f "$tmp_file"
    fi
}

# Excess sessions are killed immediately every scan cycle. No account locking.

while true; do
    if [[ ! -s "$DB_FILE" ]]; then
        sleep "$SCAN_INTERVAL"
        continue
    fi
    
    # Daily reset logic
    today=$(date +%Y-%m-%d)
    if [[ ! -f "$BW_DIR/current_date" ]]; then
        echo "$today" > "$BW_DIR/current_date"
    fi
    saved_date=$(cat "$BW_DIR/current_date" 2>/dev/null || echo "$today")
    if [[ "$today" != "$saved_date" ]]; then
        # New day! Reset daily usage and unlock users locked due to daily limit
        rm -f "$BW_DIR/"*.daily_usage 2>/dev/null
        for locked_file in "$BW_DIR/"*.daily_locked; do
            [[ -f "$locked_file" ]] || continue
            locked_user=$(basename "$locked_file" .daily_locked)
            usermod -U "$locked_user" &>/dev/null
            rm -f "$locked_file"
        done
        echo "$today" > "$BW_DIR/current_date"
    fi

    # Connection limit auto-unlock: check marker files and unlock after CONN_LOCK_DURATION seconds
    for conn_lock_file in "$BW_DIR/"*.conn_locked; do
        [[ -f "$conn_lock_file" ]] || continue
        lock_ts=0
        read -r lock_ts < "$conn_lock_file" 2>/dev/null || lock_ts=0
        [[ "$lock_ts" =~ ^[0-9]+$ ]] || lock_ts=0
        printf -v now_ts '%(%s)T' -1
        if (( now_ts - lock_ts >= CONN_LOCK_DURATION )); then
            conn_locked_user=$(basename "$conn_lock_file" .conn_locked)
            usermod -U "$conn_locked_user" &>/dev/null
            rm -f "$conn_lock_file"
        fi
    done

    printf -v current_ts '%(%s)T' -1
    dynamic_banners_enabled=false

    # Reset associative arrays each cycle (unset first to avoid stale data)
    unset session_pids locked_users uid_to_user loginuid_pids
    declare -A session_pids=()
    declare -A locked_users=()
    declare -A uid_to_user=()
    declare -A loginuid_pids=()

    while IFS=: read -r username _ uid _rest; do
        [[ -n "$username" && "$uid" =~ ^[0-9]+$ ]] && uid_to_user["$uid"]="$username"
    done < /etc/passwd

    # Method 1: process owner from ps (primary source for connection counting)
    # sshd-session is the user-owned process on Ubuntu 24.04+ (OpenSSH 9.8+)
    # On Ubuntu 22, the per-session sshd is user-owned instead.
    # Either way, exactly 1 user-owned process exists per SSH session.
    while read -r ssh_pid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue
        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" ]]; then
            session_pids["$ssh_owner"]+="$ssh_pid "
        fi
    done < <(ps -C sshd,sshd-session -o pid=,user= 2>/dev/null)

    # Method 2: kernel loginuid (reliable even when sshd runs as root)
    for p in /proc/[0-9]*/loginuid; do
        [[ -f "$p" ]] || continue
        login_uid=""
        read -r login_uid < "$p" || login_uid=""
        [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]] || continue

        session_user="${uid_to_user[$login_uid]}"
        [[ -n "$session_user" ]] || continue

        pid_dir=$(dirname "$p")
        pid_num=$(basename "$pid_dir")
        comm=""
        read -r comm < "$pid_dir/comm" || comm=""
        [[ "$comm" == "sshd" ]] || continue

        ppid_val=""
        while read -r key value; do
            if [[ "$key" == "PPid:" ]]; then
                ppid_val="${value:-}"
                break
            fi
        done < "$pid_dir/status"
        [[ "$ppid_val" == "1" ]] && continue

        loginuid_pids["$session_user"]+="$pid_num "
    done

    # Detect locked users via /etc/shadow (cheaper than passwd -Sa)
    if [[ -r /etc/shadow ]]; then
        while IFS=: read -r shadow_user shadow_hash _rest; do
            [[ -n "$shadow_user" && "${shadow_hash:0:1}" == "!" ]] && locked_users["$shadow_user"]=1
        done < /etc/shadow
    else
        while read -r passwd_user _ passwd_status _rest; do
            [[ "$passwd_status" == "L" ]] && locked_users["$passwd_user"]=1
        done < <(passwd -Sa 2>/dev/null)
    fi

    if [[ -f "/etc/visibleTech/banners_enabled" ]]; then
        mkdir -p "$BANNER_DIR"
        dynamic_banners_enabled=true
    fi

    while IFS=: read -r user pass expiry limit bandwidth_gb daily_bandwidth_gb _extra; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        
        [[ ! "$daily_bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]] && daily_bandwidth_gb=0

        # CRITICAL: unset before declare to reset per-user (bash declare is function-scoped)
        unset unique_pids
        declare -A unique_pids=()

        # Use ONLY ps-based session_pids for connection counting.
        # loginuid_pids can double-count (root-owned sshd has user's loginuid on Ubuntu 24)
        for pid in ${session_pids[$user]}; do
            [[ "$pid" =~ ^[0-9]+$ ]] && unique_pids["$pid"]=1
        done

        online_count=${#unique_pids[@]}
        user_locked=false
        if [[ -n "${locked_users[$user]+x}" ]]; then
            user_locked=true
        fi

        expiry_ts=0
        if [[ "$expiry" != "Never" && -n "$expiry" && "$expiry" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    killall -u "$user" -9 &>/dev/null
                    locked_users["$user"]=1
                fi
                continue
            fi
        fi

        [[ "$limit" =~ ^[0-9]+$ ]] || limit=1
        if (( online_count > limit )); then
            # Kill only the EXCESS sessions, keep the oldest ones alive
            sorted_pids=()
            for pid in "${!unique_pids[@]}"; do
                sorted_pids+=("$pid")
            done
            IFS=$'\n' sorted_pids=($(sort -n <<<"${sorted_pids[*]}")); unset IFS

            for (( i=limit; i<${#sorted_pids[@]}; i++ )); do
                kill -9 "${sorted_pids[$i]}" &>/dev/null
            done

            # Remove killed PIDs from unique_pids so bandwidth tracking is correct
            for (( i=limit; i<${#sorted_pids[@]}; i++ )); do
                unset unique_pids["${sorted_pids[$i]}"]
            done
            online_count=${#unique_pids[@]}
        fi

        if $dynamic_banners_enabled; then
            days_left="N/A"
            if [[ "$expiry" != "Never" && -n "$expiry" && "$expiry_ts" =~ ^[0-9]+$ && $expiry_ts -gt 0 ]]; then
                diff_secs=$((expiry_ts - current_ts))
                if (( diff_secs <= 0 )); then
                    days_left="EXPIRED"
                else
                    d_l=$(( diff_secs / 86400 ))
                    h_l=$(( (diff_secs % 86400) / 3600 ))
                    if (( d_l == 0 )); then
                        days_left="${h_l}h left"
                    else
                        days_left="${d_l}d ${h_l}h"
                    fi
                fi
            fi

            bw_info="Unlimited"
            if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
                usagefile="$BW_DIR/${user}.usage"
                accum_disp=0
                if [[ -f "$usagefile" ]]; then
                    read -r accum_disp < "$usagefile"
                    [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0
                fi
                used_gb_int=$((accum_disp / 1073741824))
                used_gb_frac=$(( (accum_disp % 1073741824) * 100 / 1073741824 ))
                printf -v used_gb "%d.%02d" "$used_gb_int" "$used_gb_frac"
                quota_b=$(( ${bandwidth_gb%%.*} * 1073741824 ))
                remain_b=$(( quota_b - accum_disp ))
                (( remain_b < 0 )) && remain_b=0
                remain_gb_int=$((remain_b / 1073741824))
                remain_gb_frac=$(( (remain_b % 1073741824) * 100 / 1073741824 ))
                printf -v remain_gb "%d.%02d" "$remain_gb_int" "$remain_gb_frac"
                bw_info="${used_gb}/${bandwidth_gb} GB used | ${remain_gb} GB left"
           fi
            
            banner_content="<center>"
            banner_content+="<font color=\"white\"><b>𝕍𝕀𝕊𝕀𝔹𝕃𝔼 𝕋𝔼ℂℍ 𝕍ℙ𝕊 ℂ𝕃𝕀𝔼ℕ𝕋𝕊 𝕄𝔸ℕ𝔸𝔾𝔼ℝ⚙️</b></font><br>"
            banner_content+="<font color=\"red\"><b>✩𝐓𝐇𝐄 𝐆𝐑𝐄𝐀𝐓 𝐏𝐑𝐎𝐅𝐅𝐄𝐒𝐒𝐎𝐑 .𝐈𝐧𝐜🦜✩</b></font><br>"
            banner_content+="<font color=\"yellow\">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font><br>"
            banner_content+="<font color=\"cyan\"><b>✨T̳̿͟͞A̳̿͟͞A̳̿͟͞R̳̿͟͞I̳̿͟͞F̳̿͟͞A̳̿͟͞ Z̳̿͟͞A̳̿͟͞ A̳̿͟͞C̳̿͟͞C̳̿͟͞O̳̿͟͞U̳̿͟͞N̳̿͟͞T̳̿͟͞✨</b></font><br>"
            banner_content+="<font color=\"magenta\">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font><br><br>"

            banner_content+="<font color=\"orange\">👤<b>🅹🅸🅽🅰 🅻🅰 🅰🅲🅲🅾🆄🅽🆃:</b></font> <font color=\"white\">$user</font><br>"
            banner_content+="<font color=\"blue\">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font><br>"

            banner_content+="<font color=\"lime\">📅<b> 🅂🄸🄺🅄 🅈🄰 🄺🅄🄴🅇🄿🄸🅁🄴:</b></font> <font color=\"red\">$expiry ($days_left)</font><br>"
            banner_content+="<font color=\"blue\">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font><br>"

            if [[ "$bandwidth_gb" != "0" ]]; then
                banner_content+="<font color=\"cyan\">📊<b>█▓▒𝐌𝐀𝐓𝐔𝐌𝐈𝐙𝐈 𝐉𝐔𝐌𝐋𝐀▒▓█:</b></font> <font color=\"white\">$bw_info</font><br>"
                banner_content+="<font color=\"blue\">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font><br>"
            fi

            if [[ "$daily_bandwidth_gb" != "0" ]]; then
                daily_usagefile="$BW_DIR/${user}.daily_usage"
                accum_disp=0
                if [[ -f "$daily_usagefile" ]]; then
                    read -r accum_disp < "$daily_usagefile"
                    [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0
                fi
                used_gb_int=$((accum_disp / 1073741824))
                used_gb_frac=$(( (accum_disp % 1073741824) * 100 / 1073741824 ))
                printf -v used_gb "%d.%02d" "$used_gb_int" "$used_gb_frac"
                quota_b=$(( ${daily_bandwidth_gb%%.*} * 1073741824 ))
                remain_b=$(( quota_b - accum_disp ))
                (( remain_b < 0 )) && remain_b=0
                remain_gb_int=$((remain_b / 1073741824))
                remain_gb_frac=$(( (remain_b % 1073741824) * 100 / 1073741824 ))
                printf -v remain_gb "%d.%02d" "$remain_gb_int" "$remain_gb_frac"
                daily_bw_info="${used_gb}/${daily_bandwidth_gb} GB used | ${remain_gb} GB left"
                banner_content+="<font color=\"white\">📊 <b>𝕄𝔸𝕋𝕌𝕄𝕀ℤ𝕀 𝕐𝔸 𝕊𝕀𝕂𝕌:</b></font> <font color=\"cyan\">$daily_bw_info</font><br>"
                banner_content+="<font color=\"blue\">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font><br>"
            fi

            banner_content+="<font color=\"gold\">🖲️ <b>ƒιℓє zιℓιzσ ¢σηηє¢т:</b></font> <font color=\"lightgreen\">$online_count/$limit</font><br>"
            banner_content+="<font color=\"magenta\">▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬</font><br><br>"
            banner_content+="</center>"

            write_banner_if_changed "$user" "$banner_content"
        fi
        [[ ( -z "$bandwidth_gb" || "$bandwidth_gb" == "0" ) && ( -z "$daily_bandwidth_gb" || "$daily_bandwidth_gb" == "0" ) ]] && continue

        usagefile="$BW_DIR/${user}.usage"
        accumulated=0
        if [[ -f "$usagefile" ]]; then
            read -r accumulated < "$usagefile"
            [[ "$accumulated" =~ ^[0-9]+$ ]] || accumulated=0
        fi

        if (( ${#unique_pids[@]} == 0 )); then
            rm -f "$PID_DIR/${user}__"*.last 2>/dev/null
            continue
        fi

        delta_total=0
        for pid in "${!unique_pids[@]}"; do
            io_file="/proc/$pid/io"
            cur=0
            if [[ -r "$io_file" ]]; then
                rchar=0
                wchar=0
                while read -r key value; do
                    case "$key" in
                        rchar:) rchar=${value:-0} ;;
                        wchar:) wchar=${value:-0} ;;
                    esac
                done < "$io_file"
                cur=$((rchar + wchar))
            fi

            pidfile="$PID_DIR/${user}__${pid}.last"
            if [[ -f "$pidfile" ]]; then
                read -r prev < "$pidfile"
                [[ "$prev" =~ ^[0-9]+$ ]] || prev=0
                if (( cur >= prev )); then
                    d=$((cur - prev))
                else
                    d=$cur
                fi
                delta_total=$((delta_total + d))
            fi
            printf "%s\n" "$cur" > "$pidfile"
        done

        for f in "$PID_DIR/${user}__"*.last; do
            [[ -f "$f" ]] || continue
            fpid=${f##*__}
            fpid=${fpid%.last}
            [[ -d "/proc/$fpid" ]] || rm -f "$f"
        done

        new_total=$((accumulated + delta_total))
        printf "%s\n" "$new_total" > "$usagefile"

        if awk "BEGIN{exit(!($bandwidth_gb > 0))}" 2>/dev/null; then
            quota_bytes=$(awk "BEGIN{printf \"%.0f\", $bandwidth_gb * 1073741824}")
            if [[ "$quota_bytes" =~ ^[0-9]+$ ]] && (( quota_bytes > 0 && new_total >= quota_bytes )); then
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    locked_users["$user"]=1
                    user_locked=true
                fi
            fi
        fi
        
        daily_usagefile="$BW_DIR/${user}.daily_usage"
        daily_accumulated=0
        if [[ -f "$daily_usagefile" ]]; then
            read -r daily_accumulated < "$daily_usagefile"
            [[ "$daily_accumulated" =~ ^[0-9]+$ ]] || daily_accumulated=0
        fi
        new_daily_total=$((daily_accumulated + delta_total))
        printf "%s\n" "$new_daily_total" > "$daily_usagefile"
        
        if awk "BEGIN{exit(!($daily_bandwidth_gb > 0))}" 2>/dev/null; then
            d_quota_bytes=$(awk "BEGIN{printf \"%.0f\", $daily_bandwidth_gb * 1073741824}")
            if [[ "$d_quota_bytes" =~ ^[0-9]+$ ]] && (( d_quota_bytes > 0 && new_daily_total >= d_quota_bytes )); then
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    locked_users["$user"]=1
                    user_locked=true
                    touch "$BW_DIR/${user}.daily_locked"
                fi
            fi
        fi
    done < "$DB_FILE"

    sleep "$SCAN_INTERVAL"
done
EOF
    chmod +x "$LIMITER_SCRIPT"
    # Strip DOS line endings in case menu.sh was uploaded from Windows
    sed -i 's/\r$//' "$LIMITER_SCRIPT" 2>/dev/null

    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=visibleTech Active User Limiter
After=network.target

[Service]
Type=simple
ExecStart=$LIMITER_SCRIPT
Restart=always
RestartSec=10
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
MemoryHigh=48M
MemoryMax=64M

[Install]
WantedBy=multi-user.target
EOF
    sed -i 's/\r$//' "$LIMITER_SERVICE" 2>/dev/null

    pkill -f "visibleTech-limiter" 2>/dev/null

    if ! systemctl is-active --quiet visibleTech-limiter; then
        systemctl daemon-reload
        systemctl enable visibleTech-limiter &>/dev/null
        systemctl start visibleTech-limiter --no-block &>/dev/null
        
    else
        systemctl restart visibleTech-limiter --no-block &>/dev/null
        
    fi
}

sync_runtime_components_if_needed() {
    local limiter_marker="# visibleTech limiter version 2026-07-23.8"
    cleanup_legacy_bandwidth_runtime
    setup_trial_cleanup_script >/dev/null 2>&1
    if [[ ! -f "$LIMITER_SCRIPT" ]] || ! grep -Fqx "$limiter_marker" "$LIMITER_SCRIPT" 2>/dev/null; then
        setup_limiter_service >/dev/null 2>&1
    fi
    if [[ -f "$BADVPN_SERVICE_FILE" ]]; then
        ensure_badvpn_service_is_quiet
    fi
    if [[ -f "/etc/visibleTech/banners_enabled" ]]; then
        update_ssh_banners_config
    elif [[ -f "$SSHD_FF_CONFIG" ]]; then
        disable_dynamic_ssh_banner_system
        systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || true
    fi
}

setup_bandwidth_service() {
    mkdir -p "$BANDWIDTH_DIR"
    # Bandwidth monitoring is now integrated into the limiter service above.
    cleanup_legacy_bandwidth_runtime
}

cleanup_legacy_bandwidth_runtime() {
    local needs_reload=false

    systemctl stop visibleTech-bandwidth &>/dev/null || true
    systemctl disable visibleTech-bandwidth &>/dev/null || true
    pkill -f "visibleTech-bandwidth" &>/dev/null || true

    if [[ -e "$BANDWIDTH_SERVICE" || -e "$BANDWIDTH_SCRIPT" || -e "$LEGACY_BANDWIDTH_DIR" ]]; then
        rm -f "$BANDWIDTH_SERVICE" "$BANDWIDTH_SCRIPT" 2>/dev/null
        rm -rf "$LEGACY_BANDWIDTH_DIR" 2>/dev/null
        needs_reload=true
    fi

    if $needs_reload; then
        systemctl daemon-reload &>/dev/null || true
    fi
}

setup_trial_cleanup_script() {
    cat > "$TRIAL_CLEANUP_SCRIPT" << 'TREOF'
#!/bin/bash
# visibleTech Trial Account Auto-Cleanup
# Usage: visibleTech-trial-cleanup.sh <username>
DB_FILE="/etc/visibleTech/users.db"
BW_DIR="/etc/visibleTech/bandwidth"

username="$1"
if [[ -z "$username" ]]; then exit 1; fi

db_line=$(grep "^${username}:" "$DB_FILE" 2>/dev/null | head -n 1)
if [[ -z "$db_line" ]]; then exit 0; fi

IFS=: read -r _ _ _ _ _ trial_marker _rest <<< "$db_line"
if [[ "$trial_marker" != "trial" ]]; then
    exit 0
fi

# Kill active sessions
killall -u "$username" -9 &>/dev/null
pkill -9 -u "$username" &>/dev/null
sleep 1

# Delete system user
userdel -rf "$username" &>/dev/null

# Remove from DB
sed -i "/^${username}:/d" "$DB_FILE"

# Remove bandwidth tracking
rm -f "$BW_DIR/${username}.usage"
rm -rf "$BW_DIR/pidtrack/${username}"
TREOF
    chmod +x "$TRIAL_CLEANUP_SCRIPT"
}

disable_dynamic_ssh_banner_system() {
    rm -f "/etc/visibleTech/banners_enabled" "$SSHD_FF_CONFIG" /usr/local/bin/visibleTech-login-info.sh 2>/dev/null
    rm -rf "/etc/visibleTech/banners" 2>/dev/null
    invalidate_banner_cache
}

disable_static_ssh_banner_in_sshd_config() {
    sed -i.bak -E "s|^[[:space:]]*Banner[[:space:]]+$SSH_BANNER_FILE[[:space:]]*$|# Banner $SSH_BANNER_FILE|" /etc/ssh/sshd_config 2>/dev/null
}

is_static_ssh_banner_enabled() {
    grep -q -E "^[[:space:]]*Banner[[:space:]]+$SSH_BANNER_FILE[[:space:]]*$" /etc/ssh/sshd_config 2>/dev/null && [ -f "$SSH_BANNER_FILE" ]
}

is_dynamic_ssh_banner_enabled() {
    [[ -f "/etc/visibleTech/banners_enabled" && -f "$SSHD_FF_CONFIG" ]]
}

get_ssh_banner_mode() {
    if is_dynamic_ssh_banner_enabled; then
        echo "dynamic"
    elif is_static_ssh_banner_enabled; then
        echo "static"
    else
        echo "disabled"
    fi
}

refresh_dynamic_banner_routing_if_enabled() {
    if is_dynamic_ssh_banner_enabled; then
        update_ssh_banners_config
    fi
}

update_ssh_banners_config() {
    local tmp_conf

    if [[ ! -f "/etc/visibleTech/banners_enabled" ]]; then
        if [[ -f "$SSHD_FF_CONFIG" ]]; then
            rm -f "$SSHD_FF_CONFIG" 2>/dev/null
            systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
        fi
        return
    fi

    ensure_visibleTech_dirs
    tmp_conf="/tmp/ff_banners_new.conf"
    echo "# visibleTech - Dynamic per-user SSH banners" > "$tmp_conf"

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r u _rest; do
            [[ -z "$u" || "$u" == \#* ]] && continue
            echo "Match User $u" >> "$tmp_conf"
            echo "    Banner /etc/visibleTech/banners/${u}.txt" >> "$tmp_conf"
        done < "$DB_FILE"
    fi

    if ! cmp -s "$tmp_conf" "$SSHD_FF_CONFIG" 2>/dev/null; then
        mv "$tmp_conf" "$SSHD_FF_CONFIG"
        if ! grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
            echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        fi
        systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
    else
        rm -f "$tmp_conf"
    fi
}

setup_ssh_login_info() {
    ensure_visibleTech_dirs || return 1
    if ! touch "/etc/visibleTech/banners_enabled"; then
        echo -e "${C_RED}❌ Failed to enable dynamic SSH banners.${C_RESET}"
        return 1
    fi
    disable_static_ssh_banner_in_sshd_config
    update_ssh_banners_config
    return 0
}


generate_dns_record() {
    echo -e "\n${C_BLUE}⚙️ Generating a random domain...${C_RESET}"
    if ! command -v jq &> /dev/null; then
        echo -e "${C_YELLOW}⚠️ jq not found, attempting to install...${C_RESET}"
        ff_pkg_install jq >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to install jq. Cannot manage DNS records.${C_RESET}"
            return 1
        }
    fi
    local SERVER_IPV4
    SERVER_IPV4=$(curl -s -4 icanhazip.com)
    if ! _is_valid_ipv4 "$SERVER_IPV4"; then
        echo -e "\n${C_RED}❌ Error: Could not retrieve a valid public IPv4 address from icanhazip.com.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Please check your server's network connection and DNS resolver settings.${C_RESET}"
        echo -e "   Output received: '$SERVER_IPV4'"
        return 1
    fi

    local SERVER_IPV6
    SERVER_IPV6=$(curl -s -6 icanhazip.com --max-time 5)

    local RANDOM_SUBDOMAIN="vps-$(tr -dc a-z0-9 < /dev/urandom | head -c 8)"
    local FULL_DOMAIN="$RANDOM_SUBDOMAIN.$DESEC_DOMAIN"
    local HAS_IPV6="false"

    local API_DATA
    API_DATA=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}]' "$RANDOM_SUBDOMAIN" "$SERVER_IPV4")

    if [[ -n "$SERVER_IPV6" ]]; then
        local aaaa_record
        aaaa_record=$(printf ',{"subname": "%s", "type": "AAAA", "ttl": 3600, "records": ["%s"]}' "$RANDOM_SUBDOMAIN" "$SERVER_IPV6")
        API_DATA="${API_DATA%?}${aaaa_record}]"
        HAS_IPV6="true"
    fi

    local CREATE_RESPONSE
    CREATE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
        -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" \
        --data "$API_DATA")
    
    local HTTP_CODE=${CREATE_RESPONSE: -3}
    local RESPONSE_BODY=${CREATE_RESPONSE:0:${#CREATE_RESPONSE}-3}

    if [[ "$HTTP_CODE" -ne 201 ]]; then
        echo -e "${C_RED}❌ Failed to create DNS records. API returned HTTP $HTTP_CODE.${C_RESET}"
        if ! echo "$RESPONSE_BODY" | jq . > /dev/null 2>&1; then
            echo "Raw Response: $RESPONSE_BODY"
        else
            echo "Response: $RESPONSE_BODY" | jq
        fi
        return 1
    fi
    
    cat > "$DNS_INFO_FILE" <<-EOF
SUBDOMAIN="$RANDOM_SUBDOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
HAS_IPV6="$HAS_IPV6"
EOF
    echo -e "\n${C_GREEN}✅ Successfully created domain: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
}

delete_dns_record() {
    if [ ! -f "$DNS_INFO_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No domain to delete.${C_RESET}"
        return
    fi
    echo -e "\n${C_BLUE}🗑️ Deleting DNS records...${C_RESET}"
    source "$DNS_INFO_FILE"
    if [[ -z "$SUBDOMAIN" ]]; then
        echo -e "${C_RED}❌ Could not read record details from config file. Skipping deletion.${C_RESET}"
        return
    fi

    curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" \
         -H "Authorization: Token $DESEC_TOKEN" > /dev/null

    if [[ "$HAS_IPV6" == "true" ]]; then
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/AAAA/" \
             -H "Authorization: Token $DESEC_TOKEN" > /dev/null
    fi

    echo -e "\n${C_GREEN}✅ Deleted domain: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
    rm -f "$DNS_INFO_FILE"
}

dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Domain Management ---${C_RESET}"
    if [ -f "$DNS_INFO_FILE" ]; then
        source "$DNS_INFO_FILE"
        echo -e "\nℹ️ A domain already exists for this server:"
        echo -e "  - ${C_CYAN}Domain:${C_RESET} ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
        echo
        read -p "👉 Do you want to DELETE this domain? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            delete_dns_record
        else
            echo -e "\n${C_YELLOW}❌ Action cancelled.${C_RESET}"
        fi
    else
        echo -e "\nℹ️ No domain has been generated for this server yet."
        echo
        read -p "👉 Do you want to generate a new random domain now? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            generate_dns_record
        else
            echo -e "\n${C_YELLOW}❌ Action cancelled.${C_RESET}"
        fi
    fi
}

_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    if [[ ! -s $DB_FILE ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found in the database.${C_RESET}"
        SELECTED_USER="NO_USERS"; return
    fi
    
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    local -A all_user_lookup=()
    local username
    for username in "${all_users[@]}"; do
        all_user_lookup["$username"]=1
    done
    
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Enter a search term (or press Enter to list all): " search_term
        if [[ -n "$search_term" ]]; then
            mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term")
        else
            users=("${all_users[@]}")
        fi
    else
        users=("${all_users[@]}")
    fi

    if [ ${#users[@]} -eq 0 ]; then
        echo -e "\n${C_YELLOW}ℹ️ No users found matching your criteria.${C_RESET}"
        SELECTED_USER="NO_USERS"; return
    fi
    echo -e "\nPlease select a user:\n"
    for i in "${!users[@]}"; do
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"
    done
    echo -e "\n  ${C_RED} [ 0]${C_RESET} ↩️ Cancel"
    echo -e "${C_CYAN}💡 Tip: you can also type the exact username directly.${C_RESET}"
    echo
    local choice
    while true; do
        if ! read -r -p "👉 Enter the number or exact username: " choice; then
            echo
            SELECTED_USER=""
            return
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#users[@]}" ]; then
            if [ "$choice" -eq 0 ]; then
                SELECTED_USER=""; return
            else
                SELECTED_USER="${users[$((choice-1))]}"; return
            fi
        elif [[ -n "${all_user_lookup[$choice]+x}" ]]; then
            SELECTED_USER="$choice"; return
        else
            echo -e "${C_RED}❌ Invalid selection. Please try again.${C_RESET}"
        fi
    done
}

_select_multi_user_interface() {
    local title="$1"
    local include_orphan_users="${2:-false}"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    SELECTED_USERS=()
    local -a all_users=()
    local -a orphan_users=()
    local -A all_user_lookup=()
    local -A orphan_user_lookup=()
    local username

    if [[ -s $DB_FILE ]]; then
        mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    fi

    if [[ "$include_orphan_users" == "true" ]]; then
        mapfile -t orphan_users < <(get_visibleTech_orphan_users)
        for username in "${orphan_users[@]}"; do
            orphan_user_lookup["$username"]=1
            if ! printf "%s\n" "${all_users[@]}" | grep -Fxq "$username"; then
                all_users+=("$username")
            fi
        done
        if [[ ${#all_users[@]} -gt 0 ]]; then
            mapfile -t all_users < <(printf "%s\n" "${all_users[@]}" | sort)
        fi
    fi

    if [[ ${#all_users[@]} -eq 0 ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found in the manager database.${C_RESET}"
        if [[ "$include_orphan_users" == "true" ]]; then
            echo -e "${C_DIM}No orphan visibleTech system users were found either.${C_RESET}"
        fi
        SELECTED_USERS=("NO_USERS"); return
    fi

    for username in "${all_users[@]}"; do
        all_user_lookup["$username"]=1
    done
    
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Enter a search term (or press Enter to list all): " search_term
        if [[ -n "$search_term" ]]; then
            mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term")
        else
            users=("${all_users[@]}")
        fi
    else
        users=("${all_users[@]}")
    fi

    if [ ${#users[@]} -eq 0 ]; then
        echo -e "\n${C_YELLOW}ℹ️ No users found matching your criteria.${C_RESET}"
        SELECTED_USERS=("NO_USERS"); return
    fi
    echo -e "\nPlease select users:\n"
    for i in "${!users[@]}"; do
        local display_user="${users[$i]}"
        if [[ "$include_orphan_users" == "true" && -n "${orphan_user_lookup[${users[$i]}]+x}" ]]; then
            display_user="${display_user} ${C_DIM}(system-only)${C_RESET}"
        fi
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "$display_user"
    done
    echo -e "\n  ${C_GREEN}[all]${C_RESET} Select ALL listed users"
    echo -e "  ${C_RED}  [0]${C_RESET} ↩️ Cancel and return to main menu"
    echo -e "\n${C_CYAN}💡 You can select multiple by number, range, or exact username.${C_RESET}"
    echo -e "${C_CYAN}   Examples: '1 3 5' or '1,3' or '1-4' or 'alice bob'${C_RESET}"
    if [[ "$include_orphan_users" == "true" ]]; then
        echo -e "${C_CYAN}   Users marked '(system-only)' are old accounts still on the VPS but missing from users.db${C_RESET}"
    fi
    echo
    local choice
    while true; do
        if ! read -r -p "👉 Enter user numbers or usernames: " choice; then
            echo
            SELECTED_USERS=()
            return
        fi
        choice=${choice//,/ } # Replace commas with spaces
        
        if [[ -z "$choice" ]]; then
            echo -e "${C_RED}❌ Invalid selection. Please try again.${C_RESET}"
            continue
        fi

        if [[ "$choice" == "0" ]]; then
            SELECTED_USERS=(); return
        fi
        
        if [[ "${choice,,}" == "all" ]]; then
            SELECTED_USERS=("${users[@]}")
            return
        fi
        
        local valid=true
        local selected_indices=()
        local selected_names=()
        for token in $choice; do
            if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
                local start=${token%-*}
                local end=${token#*-}
                if [ "$start" -le "$end" ]; then
                    for (( idx=start; idx<=end; idx++ )); do
                        if [ "$idx" -ge 1 ] && [ "$idx" -le "${#users[@]}" ]; then
                            selected_indices+=($idx)
                        else
                            valid=false; break
                        fi
                    done
                else
                    valid=false; break
                fi
            elif [[ "$token" =~ ^[0-9]+$ ]]; then
                if [ "$token" -ge 1 ] && [ "$token" -le "${#users[@]}" ]; then
                    selected_indices+=($token)
                elif [[ -n "${all_user_lookup[$token]+x}" ]]; then
                    selected_names+=("$token")
                else
                    valid=false; break
                fi
            elif [[ -n "${all_user_lookup[$token]+x}" ]]; then
                selected_names+=("$token")
            else
                valid=false; break
            fi
        done
        
        if [[ "$valid" == true && ( ${#selected_indices[@]} -gt 0 || ${#selected_names[@]} -gt 0 ) ]]; then
            mapfile -t unique_indices < <(printf "%s\n" "${selected_indices[@]}" | sort -u -n)
            for idx in "${unique_indices[@]}"; do
                SELECTED_USERS+=("${users[$((idx-1))]}")
            done
            if (( ${#selected_names[@]} > 0 )); then
                mapfile -t unique_names < <(printf "%s\n" "${selected_names[@]}" | sort -u)
                for username in "${unique_names[@]}"; do
                    if [[ -n "$username" ]] && ! printf "%s\n" "${SELECTED_USERS[@]}" | grep -Fxq "$username"; then
                        SELECTED_USERS+=("$username")
                    fi
                done
            fi
            return
        else
            echo -e "${C_RED}❌ Invalid selection. Please check your numbers or usernames.${C_RESET}"
            SELECTED_USERS=()
            selected_indices=()
            selected_names=()
        fi
    done
}

get_user_status() {
    local username="$1"
    if ! id "$username" &>/dev/null; then echo -e "${C_RED}Not Found${C_RESET}"; return; fi
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then echo -e "${C_YELLOW}🔒 Locked${C_RESET}"; return; fi
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    if [[ $expiry_ts -lt $current_ts ]]; then echo -e "${C_RED}🗓️ Expired${C_RESET}"; return; fi
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create New SSH User ---${C_RESET}"
    read -p "👉 Enter username (or '0' to cancel): " username
    local adopt_existing=false
    if [[ "$username" == "0" ]]; then
        echo -e "\n${C_YELLOW}❌ User creation cancelled.${C_RESET}"
        return
    fi
    if [[ -z "$username" ]]; then
        echo -e "\n${C_RED}❌ Error: Username cannot be empty.${C_RESET}"
        return
    fi
    if db_has_user "$username"; then
        echo -e "\n${C_RED}❌ Error: User '$username' already exists in visibleTech.${C_RESET}"
        return
    fi
    if id "$username" &>/dev/null; then
        if is_visibleTech_orphan_user "$username"; then
            echo -e "\n${C_YELLOW}⚠️ User '$username' already exists on the system but is missing from users.db.${C_RESET}"
            echo -e "${C_DIM}This usually happens after uninstalling the script without deleting the SSH users.${C_RESET}"
            read -p "👉 Do you want to take control of this existing user and manage it with visibleTech? (y/n): " adopt_confirm
            if [[ "$adopt_confirm" == "y" || "$adopt_confirm" == "Y" ]]; then
                adopt_existing=true
            else
                echo -e "\n${C_YELLOW}❌ User creation cancelled.${C_RESET}"
                return
            fi
        else
            echo -e "\n${C_RED}❌ Error: System user '$username' already exists and does not look like a visibleTech SSH account.${C_RESET}"
            return
        fi
    fi
    local password=""
    while true; do
        read -p "🔑 Enter password (or press Enter for auto-generated): " password
        if [[ -z "$password" ]]; then
            password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
            echo -e "${C_GREEN}🔑 Auto-generated password: ${C_YELLOW}$password${C_RESET}"
            break
        else
            break
        fi
    done
    read -p "🗓️ Enter account duration (in days) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    read -p "📶 Enter simultaneous connection limit [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    read -p "📦 Enter bandwidth limit in GB (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    read -p "📦 Enter DAILY bandwidth limit in GB (0 = unlimited) [0]: " daily_bandwidth_gb
    daily_bandwidth_gb=${daily_bandwidth_gb:-0}
    if ! [[ "$daily_bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    local expire_date
    expire_date=$(date -d "+$days days" +%Y-%m-%d)
    ensure_visibleTech_system_group
    if [[ "$adopt_existing" == "true" ]]; then
        usermod -s /usr/sbin/nologin "$username" &>/dev/null
    else
        useradd -m -s /usr/sbin/nologin "$username"
    fi
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd; chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb:$daily_bandwidth_gb:trial" >> "$DB_FILE"
    
    local bw_display="Unlimited"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
    local daily_bw_display="Unlimited"
    if [[ "$daily_bandwidth_gb" != "0" ]]; then daily_bw_display="${daily_bandwidth_gb} GB/day"; fi
    
    clear; show_banner
    if [[ "$adopt_existing" == "true" ]]; then
        echo -e "${C_GREEN}✅ Existing system user '$username' has been imported into visibleTech!${C_RESET}\n"
    else
        echo -e "${C_GREEN}✅ User '$username' created successfully!${C_RESET}\n"
    fi
    echo -e "  - 👤 Username:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Password:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - 🗓️ Expires on:        ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  - 📶 Connection Limit:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Total Bandwidth:   ${C_YELLOW}$bw_display${C_RESET}"
    echo -e "  - 📦 Daily Bandwidth:   ${C_YELLOW}$daily_bw_display${C_RESET}"
    echo -e "    ${C_DIM}(Active monitoring service will enforce these limits)${C_RESET}"

    # Auto-ask for config generation
    echo
    read -p "👉 Do you want to generate a client connection config for this user? (y/n): " gen_conf
    if [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]]; then
        generate_client_config "$username" "$password"
    fi
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete visibleTech Users ---" "true"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_RED}⚠️ You selected ${#SELECTED_USERS[@]} user(s) to delete: ${C_YELLOW}${SELECTED_USERS[*]}${C_RESET}"
    read -p "👉 Are you sure you want to PERMANENTLY delete them? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "\n${C_YELLOW}❌ Deletion cancelled.${C_RESET}"; return; fi
    
    echo -e "\n${C_BLUE}🗑️ Deleting selected users...${C_RESET}"
    delete_visibleTech_user_accounts "${SELECTED_USERS[@]}"
}

edit_user() {
    _select_user_interface "--- ✏️ Edit a User ---"
    local username=$SELECTED_USER
    if [[ "$username" == "NO_USERS" ]] || [[ -z "$username" ]]; then return; fi
    while true; do
        clear; show_banner; echo -e "${C_BOLD}${C_PURPLE}--- Editing User: ${C_YELLOW}$username${C_PURPLE} ---${C_RESET}"
        
        # Show current user details
        local current_line; current_line=$(grep "^$username:" "$DB_FILE")
        local cur_pass cur_expiry cur_limit cur_bw cur_daily_bw
        IFS=: read -r _ cur_pass cur_expiry cur_limit cur_bw cur_daily_bw _ <<< "$current_line"
        [[ -z "$cur_bw" ]] && cur_bw="0"
        [[ ! "$cur_daily_bw" =~ ^[0-9]+\.?[0-9]*$ ]] && cur_daily_bw="0"
        
        local cur_bw_display="Unlimited"; [[ "$cur_bw" != "0" ]] && cur_bw_display="${cur_bw} GB"
        local cur_daily_bw_display="Unlimited"; [[ "$cur_daily_bw" != "0" ]] && cur_daily_bw_display="${cur_daily_bw} GB/day"
        
        # Show bandwidth usage
        local bw_used_display="N/A"
        if [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
            local used_bytes=0; read -r used_bytes < "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null || used_bytes=0
            if [[ -n "$used_bytes" && "$used_bytes" != "0" ]]; then
                bw_used_display=$(awk "BEGIN {printf \"%.2f GB\", $used_bytes / 1073741824}")
            else
                bw_used_display="0.00 GB"
            fi
        fi
        
        local daily_bw_used_display="N/A"
        if [[ -f "$BANDWIDTH_DIR/${username}.daily_usage" ]]; then
            local d_used_bytes=0; read -r d_used_bytes < "$BANDWIDTH_DIR/${username}.daily_usage" 2>/dev/null || d_used_bytes=0
            if [[ -n "$d_used_bytes" && "$d_used_bytes" != "0" ]]; then
                daily_bw_used_display=$(awk "BEGIN {printf \"%.2f GB\", $d_used_bytes / 1073741824}")
            else
                daily_bw_used_display="0.00 GB"
            fi
        fi
        
        echo -e "\n  ${C_DIM}Current: Pass=${C_YELLOW}$cur_pass${C_RESET}${C_DIM} Exp=${C_YELLOW}$cur_expiry${C_RESET}${C_DIM} Conn=${C_YELLOW}$cur_limit${C_RESET}${C_DIM} BW=${C_YELLOW}$cur_bw_display${C_RESET}${C_DIM} Used=${C_CYAN}$bw_used_display${C_RESET}${C_DIM} Daily BW=${C_YELLOW}$cur_daily_bw_display${C_RESET}${C_DIM} Daily Used=${C_CYAN}$daily_bw_used_display${C_RESET}"
        echo -e "\nSelect a detail to edit:\n"
        printf "  ${C_GREEN}[ 1]${C_RESET} %-35s\n" "🔑 Change Password"
        printf "  ${C_GREEN}[ 2]${C_RESET} %-35s\n" "🗓️ Change Expiration Date"
        printf "  ${C_GREEN}[ 3]${C_RESET} %-35s\n" "📶 Change Connection Limit"
        printf "  ${C_GREEN}[ 4]${C_RESET} %-35s\n" "📦 Change Total Bandwidth Limit"
        printf "  ${C_GREEN}[ 5]${C_RESET} %-35s\n" "📦 Change Daily Bandwidth Limit"
        printf "  ${C_GREEN}[ 6]${C_RESET} %-35s\n" "🔄 Reset Bandwidth Counters"
        echo -e "\n  ${C_RED}[ 0]${C_RESET} ✅ Finish Editing"
        echo
        if ! read -r -p "👉 Enter your choice: " edit_choice; then
            echo
            return
        fi
        case $edit_choice in
            1)
               local new_pass=""
               read -p "Enter new password (or press Enter for auto-generated): " new_pass
               if [[ -z "$new_pass" ]]; then
                   new_pass=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
                   echo -e "${C_GREEN}🔑 Auto-generated: ${C_YELLOW}$new_pass${C_RESET}"
               fi
               echo "$username:$new_pass" | chpasswd
               sed -i "s/^$username:.*/$username:$new_pass:$cur_expiry:$cur_limit:$cur_bw:$cur_daily_bw/" "$DB_FILE"
               echo -e "\n${C_GREEN}✅ Password for '$username' changed to: ${C_YELLOW}$new_pass${C_RESET}"
               ;;
            2) read -p "Enter new duration (in days from today): " days
               if [[ "$days" =~ ^[0-9]+$ ]]; then
                   local new_expire_date; new_expire_date=$(date -d "+$days days" +%Y-%m-%d); chage -E "$new_expire_date" "$username"
                   sed -i "s/^$username:.*/$username:$cur_pass:$new_expire_date:$cur_limit:$cur_bw:$cur_daily_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Expiration for '$username' set to ${C_YELLOW}$new_expire_date${C_RESET}."
               else echo -e "\n${C_RED}❌ Invalid number of days.${C_RESET}"; fi ;;
            3) read -p "Enter new simultaneous connection limit: " new_limit
               if [[ "$new_limit" =~ ^[0-9]+$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$new_limit:$cur_bw:$cur_daily_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Connection limit for '$username' set to ${C_YELLOW}$new_limit${C_RESET}."
               else echo -e "\n${C_RED}❌ Invalid limit.${C_RESET}"; fi ;;
            4) read -p "Enter new TOTAL bandwidth limit in GB (0 = unlimited): " new_bw
               if [[ "$new_bw" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$new_bw:$cur_daily_bw/" "$DB_FILE"
                   local bw_msg="Unlimited"; [[ "$new_bw" != "0" ]] && bw_msg="${new_bw} GB"
                   echo -e "\n${C_GREEN}✅ Total bandwidth limit for '$username' set to ${C_YELLOW}$bw_msg${C_RESET}."
                   # Unlock user if they were locked due to bandwidth
                   if [[ "$new_bw" == "0" ]] || [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
                       local used_bytes; used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null || echo 0)
                       local new_quota_bytes; new_quota_bytes=$(awk "BEGIN {printf \"%.0f\", $new_bw * 1073741824}")
                       if [[ "$new_bw" == "0" ]] || [[ "$used_bytes" -lt "$new_quota_bytes" ]]; then
                           usermod -U "$username" &>/dev/null
                       fi
                   fi
               else echo -e "\n${C_RED}❌ Invalid bandwidth value.${C_RESET}"; fi ;;
            5) read -p "Enter new DAILY bandwidth limit in GB (0 = unlimited): " new_daily_bw
               if [[ "$new_daily_bw" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$cur_bw:$new_daily_bw/" "$DB_FILE"
                   local daily_bw_msg="Unlimited"; [[ "$new_daily_bw" != "0" ]] && daily_bw_msg="${new_daily_bw} GB/day"
                   echo -e "\n${C_GREEN}✅ Daily bandwidth limit for '$username' set to ${C_YELLOW}$daily_bw_msg${C_RESET}."
                   # Unlock user if they were locked due to daily bandwidth
                   if [[ "$new_daily_bw" == "0" ]] || [[ -f "$BANDWIDTH_DIR/${username}.daily_usage" ]]; then
                       local d_used_bytes; d_used_bytes=$(cat "$BANDWIDTH_DIR/${username}.daily_usage" 2>/dev/null || echo 0)
                       local new_d_quota_bytes; new_d_quota_bytes=$(awk "BEGIN {printf \"%.0f\", $new_daily_bw * 1073741824}")
                       if [[ "$new_daily_bw" == "0" ]] || [[ "$d_used_bytes" -lt "$new_d_quota_bytes" ]]; then
                           usermod -U "$username" &>/dev/null
                           rm -f "$BANDWIDTH_DIR/${username}.daily_locked"
                       fi
                   fi
               else echo -e "\n${C_RED}❌ Invalid bandwidth value.${C_RESET}"; fi ;;
            6)
               echo "0" > "$BANDWIDTH_DIR/${username}.usage"
               echo "0" > "$BANDWIDTH_DIR/${username}.daily_usage"
               rm -f "$BANDWIDTH_DIR/${username}.daily_locked"
               # Unlock user if they were locked due to bandwidth
               usermod -U "$username" &>/dev/null
               echo -e "\n${C_GREEN}✅ All bandwidth counters for '$username' have been reset to 0.${C_RESET}"
               ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" ;;
        esac
        echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue editing..." && read -r || return
    done
}

lock_user() {
    _select_multi_user_interface "--- 🔒 Lock Users (from DB) ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_BLUE}🔒 Locking selected users...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then
             echo -e " ❌ User '${C_YELLOW}$u${C_RESET}' does not exist on this system."
             continue
        fi
        
        usermod -L "$u"
        if [ $? -eq 0 ]; then
            killall -u "$u" -9 &>/dev/null
            echo -e " ✅ ${C_YELLOW}$u${C_RESET} locked and active sessions killed."
        else
            echo -e " ❌ Failed to lock ${C_YELLOW}$u${C_RESET}."
        fi
    done
}

unlock_user() {
    _select_multi_user_interface "--- 🔓 Unlock Users (from DB) ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_BLUE}🔓 Unlocking selected users...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then
             echo -e " ❌ User '${C_YELLOW}$u${C_RESET}' does not exist on this system."
             continue
        fi
        
        usermod -U "$u"
        if [ $? -eq 0 ]; then
            echo -e " ✅ ${C_YELLOW}$u${C_RESET} unlocked."
        else
            echo -e " ❌ Failed to unlock ${C_YELLOW}$u${C_RESET}."
        fi
    done
}

list_users() {
    clear; show_banner
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_YELLOW}ℹ️ No users are currently being managed.${C_RESET}"
        return
    fi
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Managed Users ---${C_RESET}"
    echo -e "${C_YELLOW}---------------------------------------------------------------------------------------------------${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-18s | %-12s | %-10s | %-25s | %-20s${C_RESET}\n" "USERNAME" "EXPIRATION" "SESSIONS" "BANDWIDTH" "STATUS"
    echo -e "${C_YELLOW}---------------------------------------------------------------------------------------------------${C_RESET}"

    local current_ts
    printf -v current_ts '%(%s)T' -1
    local -A system_user_lookup=()
    local -A locked_user_lookup=()

    while IFS=: read -r system_user _rest; do
        [[ -n "$system_user" ]] && system_user_lookup["$system_user"]=1
    done < /etc/passwd

    if [[ -r /etc/shadow ]]; then
        while IFS=: read -r shadow_user shadow_hash _rest; do
            [[ -n "$shadow_user" && "${shadow_hash:0:1}" == "!" ]] && locked_user_lookup["$shadow_user"]=1
        done < /etc/shadow
    else
        while read -r passwd_user _ passwd_status _rest; do
            [[ -z "$passwd_user" ]] && continue
            [[ "$passwd_status" == "L" ]] && locked_user_lookup["$passwd_user"]=1
        done < <(passwd -Sa 2>/dev/null)
    fi
    refresh_ssh_session_cache

    while IFS=: read -r user pass expiry limit bandwidth_gb daily_bandwidth_gb _extra; do
        local online_count="${SSH_SESSION_COUNTS[$user]:-0}"
        local connection_string="$online_count / $limit"
        local plain_status="Active"
        local status="${C_GREEN}🟢 Active${C_RESET}"
        local quota_exceeded=false

        [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"
        [[ ! "$daily_bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]] && daily_bandwidth_gb="0"
        
        local bw_string="Unlimited"
        local total_str=""
        local daily_str=""
        
        if [[ "$bandwidth_gb" != "0" ]]; then
            local used_bytes=0
            if [[ -f "$BANDWIDTH_DIR/${user}.usage" ]]; then
                read -r used_bytes < "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null || used_bytes=0
                [[ "$used_bytes" =~ ^[0-9]+$ ]] || used_bytes=0
            fi
            local used_gb
            used_gb=$(awk "BEGIN {printf \"%.1f\", $used_bytes / 1073741824}")
            total_str="${used_gb}/${bandwidth_gb}G"
            local quota_bytes
            quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
            if [[ "$quota_bytes" =~ ^[0-9]+$ ]] && (( used_bytes >= quota_bytes )); then
                quota_exceeded=true
            fi
        fi
        
        if [[ "$daily_bandwidth_gb" != "0" ]]; then
            local d_used_bytes=0
            if [[ -f "$BANDWIDTH_DIR/${user}.daily_usage" ]]; then
                read -r d_used_bytes < "$BANDWIDTH_DIR/${user}.daily_usage" 2>/dev/null || d_used_bytes=0
                [[ "$d_used_bytes" =~ ^[0-9]+$ ]] || d_used_bytes=0
            fi
            local d_used_gb
            d_used_gb=$(awk "BEGIN {printf \"%.1f\", $d_used_bytes / 1073741824}")
            daily_str="${d_used_gb}/${daily_bandwidth_gb}G/d"
            local d_quota_bytes
            d_quota_bytes=$(awk "BEGIN {printf \"%.0f\", $daily_bandwidth_gb * 1073741824}")
            if [[ "$d_quota_bytes" =~ ^[0-9]+$ ]] && (( d_used_bytes >= d_quota_bytes )); then
                quota_exceeded=true
            fi
        fi
        
        if [[ -n "$total_str" && -n "$daily_str" ]]; then
            bw_string="$total_str | $daily_str"
        elif [[ -n "$total_str" ]]; then
            bw_string="$total_str"
        elif [[ -n "$daily_str" ]]; then
            bw_string="$daily_str"
        fi

        if [[ -z "${system_user_lookup[$user]+x}" ]]; then
            plain_status="Not Found"
            status="${C_RED}Not Found${C_RESET}"
        elif [[ -n "$expiry" && "$expiry" != "Never" ]]; then
            local expiry_ts
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                plain_status="Expired"
                status="${C_RED}🗓️ Expired${C_RESET}"
            fi
        fi

        if [[ "$plain_status" == "Active" && "$quota_exceeded" == true ]]; then
            if [[ -n "${locked_user_lookup[$user]+x}" ]]; then
                plain_status="BW Locked"
                status="${C_RED}🔒 BW Locked${C_RESET}"
            else
                plain_status="Quota Exceeded"
                status="${C_RED}📦 Quota Exceeded${C_RESET}"
            fi
        elif [[ "$plain_status" == "Active" && -n "${locked_user_lookup[$user]+x}" ]]; then
            plain_status="Locked"
            status="${C_YELLOW}🔒 Locked${C_RESET}"
        fi

        local line_color="$C_WHITE"
        case "$plain_status" in
            "Active") line_color="$C_GREEN" ;;
            "Locked") line_color="$C_YELLOW" ;;
            "Expired") line_color="$C_RED" ;;
            "BW Locked") line_color="$C_RED" ;;
            "Quota Exceeded") line_color="$C_RED" ;;
            "Not Found") line_color="$C_DIM" ;;
        esac

        printf "${line_color}%-18s ${C_RESET}| ${C_YELLOW}%-12s ${C_RESET}| ${C_CYAN}%-10s ${C_RESET}| ${C_ORANGE}%-25s ${C_RESET}| %-20s\n" "$user" "$expiry" "$connection_string" "$bw_string" "$status"
    done < <(sort "$DB_FILE")
    echo -e "${C_CYAN}=========================================================================================${C_RESET}\n"
}

renew_user() {
    _select_multi_user_interface "--- 🔄 Renew Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    read -p "👉 Enter number of days to extend the account(s): " days; if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    local new_expire_date; new_expire_date=$(date -d "+$days days" +%Y-%m-%d)
    
    echo -e "\n${C_BLUE}🔄 Renewing selected users for $days days...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        chage -E "$new_expire_date" "$u"
        local line pass _expiry limit bw
        line=$(grep "^$u:" "$DB_FILE")
        IFS=: read -r _ pass _expiry limit bw _ <<< "$line"
        [[ -z "$bw" ]] && bw="0"
        sed -i "s/^$u:.*/$u:$pass:$new_expire_date:$limit:$bw/" "$DB_FILE"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} renewed until ${C_GREEN}${new_expire_date}${C_RESET}."
    done
}

cleanup_expired() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🧹 Cleanup Expired Users ---${C_RESET}"
    
    local expired_users=()
    local current_ts
    current_ts=$(date +%s)

    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_GREEN}✅ User database is empty. No expired users found.${C_RESET}"
        return
    fi
    
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        local expiry_ts
        expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        
        if [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]]; then
            expired_users+=("$user")
        fi
    done < "$DB_FILE"

    if [ ${#expired_users[@]} -eq 0 ]; then
        echo -e "\n${C_GREEN}✅ No expired users found.${C_RESET}"
        return
    fi

    echo -e "\nThe following users have expired: ${C_RED}${expired_users[*]}${C_RESET}"
    read -p "👉 Do you want to delete all of them? (y/n): " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo -e "\n${C_BLUE}🗑️ Deleting expired users...${C_RESET}"
        delete_visibleTech_user_accounts "${expired_users[@]}"
        echo -e "\n${C_GREEN}✅ Expired users have been cleaned up.${C_RESET}"
    else
        echo -e "\n${C_YELLOW}❌ Cleanup cancelled.${C_RESET}"
    fi
}


backup_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💾 Backup User Data ---${C_RESET}"
    read -p "👉 Enter path for backup file [/root/visibleTech_users.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/visibleTech_users.tar.gz}
    if [ ! -d "$DB_DIR" ] || [ ! -s "$DB_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No user data found to back up.${C_RESET}"
        return
    fi
    echo -e "\n${C_BLUE}⚙️ Backing up user database and settings to ${C_YELLOW}$backup_path${C_RESET}..."
    tar -czf "$backup_path" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")"
    if [ $? -eq 0 ]; then
        echo -e "\n${C_GREEN}✅ SUCCESS: User data backup created at ${C_YELLOW}$backup_path${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: Backup failed.${C_RESET}"
    fi
}

restore_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📥 Restore User Data ---${C_RESET}"
    read -p "👉 Enter the full path to the user data backup file [/root/visibleTech_users.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/visibleTech_users.tar.gz}
    if [ ! -f "$backup_path" ]; then
        echo -e "\n${C_RED}❌ ERROR: Backup file not found at '$backup_path'.${C_RESET}"
        return
    fi
    echo -e "\n${C_RED}${C_BOLD}⚠️ WARNING:${C_RESET} This will overwrite all current users and settings."
    echo -e "It will restore user accounts, passwords, limits, and expiration dates from the backup file."
    read -p "👉 Are you absolutely sure you want to proceed? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "\n${C_YELLOW}❌ Restore cancelled.${C_RESET}"; return; fi
    local temp_dir
    temp_dir=$(mktemp -d)
    echo -e "\n${C_BLUE}⚙️ Extracting backup file to a temporary location...${C_RESET}"
    tar -xzf "$backup_path" -C "$temp_dir"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ ERROR: Failed to extract backup file. Aborting.${C_RESET}"
        rm -rf "$temp_dir"
        return
    fi
    local restored_db_file="$temp_dir/visibleTech/users.db"
    if [ ! -f "$restored_db_file" ]; then
        echo -e "\n${C_RED}❌ ERROR: users.db not found in the backup. Cannot restore user accounts.${C_RESET}"
        rm -rf "$temp_dir"
        return
    fi
    echo -e "${C_BLUE}⚙️ Overwriting current user database...${C_RESET}"
    mkdir -p "$DB_DIR"
    cp "$restored_db_file" "$DB_FILE"
    if [ -d "$temp_dir/visibleTech/ssl" ]; then
        cp -r "$temp_dir/visibleTech/ssl" "$DB_DIR/"
    fi
    if [ -f "$temp_dir/visibleTech/dns_info.conf" ]; then
        cp "$temp_dir/visibleTech/dns_info.conf" "$DB_DIR/"
    fi
    if [ -d "$temp_dir/visibleTech/v2ray" ]; then
        mkdir -p "$V2_DIR"
        cp -r "$temp_dir/visibleTech/v2ray/." "$V2_DIR/"
        if v2ray_installed; then v2 render --restart >/dev/null 2>&1; fi
    fi
    
    echo -e "${C_BLUE}⚙️ Re-synchronizing system accounts with the restored database...${C_RESET}"
    ensure_visibleTech_system_group
    
    while IFS=: read -r user pass expiry limit; do
        echo "Processing user: ${C_YELLOW}$user${C_RESET}"
        if ! id "$user" &>/dev/null; then
            echo " - User does not exist in system. Creating..."
            useradd -m -s /usr/sbin/nologin "$user"
        fi
        usermod -aG "$FF_USERS_GROUP" "$user" 2>/dev/null
        echo " - Setting password..."
        echo "$user:$pass" | chpasswd
        echo " - Setting expiration to $expiry..."
        chage -E "$expiry" "$user"
        echo " - Connection limit is $limit (enforced by PAM)"
    done < "$DB_FILE"
    rm -rf "$temp_dir"
    echo -e "\n${C_GREEN}✅ SUCCESS: User data restore completed.${C_RESET}"
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

_enable_banner_in_sshd_config() {
    echo -e "\n${C_BLUE}⚙️ Configuring sshd_config...${C_RESET}"
    disable_dynamic_ssh_banner_system
    sed -i.bak -E 's/^( *Banner *).*/#\1/' /etc/ssh/sshd_config
    if ! grep -q -E "^Banner $SSH_BANNER_FILE" /etc/ssh/sshd_config; then
        echo -e "\n# visibleTech SSH Banner\nBanner $SSH_BANNER_FILE" >> /etc/ssh/sshd_config
    fi
    echo -e "${C_GREEN}✅ sshd_config updated.${C_RESET}"
}

_restart_ssh() {
    echo -e "\n${C_BLUE}🔄 Restarting SSH service to apply changes...${C_RESET}"
    local ssh_service_name=""
    if [ -f /lib/systemd/system/sshd.service ]; then
        ssh_service_name="sshd.service"
    elif [ -f /lib/systemd/system/ssh.service ]; then
        ssh_service_name="ssh.service"
    else
        echo -e "${C_RED}❌ Could not find sshd.service or ssh.service. Cannot restart SSH.${C_RESET}"
        return 1
    fi

    systemctl restart "${ssh_service_name}"
    if [ $? -eq 0 ]; then
        echo -e "${C_GREEN}✅ SSH service ('${ssh_service_name}') restarted successfully.${C_RESET}"
    else
        echo -e "${C_RED}❌ Failed to restart SSH service ('${ssh_service_name}'). Please check 'journalctl -u ${ssh_service_name}' for errors.${C_RESET}"
    fi
}

set_ssh_banner_paste() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Paste Static SSH Banner ---${C_RESET}"
    echo -e "Paste your custom banner below. Press ${C_YELLOW}[Ctrl+D]${C_RESET} when you are finished."
    echo -e "${C_DIM}This will be shown to all SSH users through 'Banner $SSH_BANNER_FILE'.${C_RESET}"
    echo -e "${C_DIM}The current banner (if any) will be overwritten.${C_RESET}"
    echo -e "--------------------------------------------------"
    cat > "$SSH_BANNER_FILE"
    chmod 644 "$SSH_BANNER_FILE"
    echo -e "\n--------------------------------------------------"
    echo -e "\n${C_GREEN}✅ Static banner content saved.${C_RESET}"
    _enable_banner_in_sshd_config
    _restart_ssh
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
}

view_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👁️ Current SSH Banner ---${C_RESET}"
    if [ -f "$SSH_BANNER_FILE" ]; then
        echo -e "\n${C_CYAN}--- BEGIN BANNER ---${C_RESET}"
        cat "$SSH_BANNER_FILE"
        echo -e "${C_CYAN}---- END BANNER ----${C_RESET}"
    else
        echo -e "\n${C_YELLOW}ℹ️ No banner file found at $SSH_BANNER_FILE.${C_RESET}"
    fi
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
}

remove_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Disable SSH Banners ---${C_RESET}"
    read -p "👉 Are you sure you want to disable all SSH banners? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo -e "\n${C_YELLOW}❌ Action cancelled.${C_RESET}"
        echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
        return
    fi
    if [ -f "$SSH_BANNER_FILE" ]; then
        rm -f "$SSH_BANNER_FILE"
        echo -e "\n${C_GREEN}✅ Removed banner file: $SSH_BANNER_FILE${C_RESET}"
    else
        echo -e "\n${C_YELLOW}ℹ️ No banner file to remove.${C_RESET}"
    fi
    disable_dynamic_ssh_banner_system
    echo -e "\n${C_BLUE}⚙️ Disabling banner in sshd_config...${C_RESET}"
    disable_static_ssh_banner_in_sshd_config
    echo -e "${C_GREEN}✅ Banner disabled in configuration.${C_RESET}"
    _restart_ssh
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
}

preview_dynamic_ssh_banner() {
    if ! is_dynamic_ssh_banner_enabled; then
        echo -e "\n${C_RED}❌ Dynamic banners are not enabled right now.${C_RESET}"
        press_enter
        return
    fi

    echo -e "${C_DIM}Refreshing dynamic banner worker...${C_RESET}"
    setup_limiter_service >/dev/null 2>&1
    _select_user_interface "--- 📝 Preview Dynamic Banner ---"
    local u=$SELECTED_USER
    if [[ -z "$u" || "$u" == "NO_USERS" ]]; then
        return
    fi

    echo -e "\n${C_CYAN}--- Dynamic Banner Preview for user '$u' ---${C_RESET}\n"
    if [[ -f "/etc/visibleTech/banners/${u}.txt" ]]; then
        cat "/etc/visibleTech/banners/${u}.txt"
    else
        echo -e "${C_RED}Banner file not generated yet. Waiting up to 10s for the worker...${C_RESET}"
        sleep 5
        if ! cat "/etc/visibleTech/banners/${u}.txt" 2>/dev/null; then
            echo -e "\n${C_RED}Still not generated. Here are the last limiter logs:${C_RESET}"
            echo -e "----------------------------------------------------------------------"
            journalctl -u visibleTech-limiter -n 15 --no-pager
            echo -e "----------------------------------------------------------------------"
        fi
    fi
    press_enter
}

# NOTE: The full ssh_banner_menu() with dynamic/static support is defined later in the file.

install_udp_custom() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing udp-custom ---${C_RESET}"
    if [ -f "$UDP_CUSTOM_SERVICE_FILE" ] || [ -f "$UDPGW_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ udp-custom is already installed.${C_RESET}"
        return
    fi

    check_and_free_ports 36712 7800 || return
    check_and_open_firewall_port 36712 udp || return

    echo -e "\n${C_GREEN}⚙️ Creating directory for udp-custom...${C_RESET}"
    rm -rf "$UDP_CUSTOM_DIR"
    mkdir -p "$UDP_CUSTOM_DIR"

    echo -e "\n${C_GREEN}⚙️ Detecting system architecture...${C_RESET}"
    local arch
    arch=$(uname -m)
    local binary_url=""
    if [[ "$arch" == "x86_64" ]]; then
        binary_url="https://github.com/wavy07/manage/raw/main/udp/udp-custom-linux-amd64"
        echo -e "${C_BLUE}ℹ️ Detected x86_64 (amd64) architecture.${C_RESET}"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_url="https://github.com/wavy07/manage/raw/main/udp/udp-custom-linux-arm"
        echo -e "${C_BLUE}ℹ️ Detected ARM64 architecture.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Unsupported architecture: $arch. Cannot install udp-custom.${C_RESET}"
        rm -rf "$UDP_CUSTOM_DIR"
        return
    fi

    echo -e "\n${C_GREEN}📥 Downloading udp-custom binary...${C_RESET}"
    wget -q --show-progress -O "$UDP_CUSTOM_DIR/udp-custom" "$binary_url"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ Failed to download the udp-custom binary.${C_RESET}"
        rm -rf "$UDP_CUSTOM_DIR"
        return
    fi
    chmod +x "$UDP_CUSTOM_DIR/udp-custom"

    echo -e "\n${C_GREEN}📦 Setting up udpgw helper...${C_RESET}"
    if [[ "$arch" == "x86_64" ]]; then
        wget -q --show-progress -O "$UDPGW_BINARY" "https://raw.githubusercontent.com/http-custom/udp-custom/main/module/udpgw"
        if [ $? -ne 0 ]; then
            echo -e "\n${C_RED}❌ Failed to download the udpgw helper binary.${C_RESET}"
            rm -rf "$UDP_CUSTOM_DIR"
            return
        fi
        chmod +x "$UDPGW_BINARY"
    else
        echo -e "${C_YELLOW}ℹ️ Architecture is $arch. Compiling udpgw from source (this may take a minute)...${C_RESET}"
        ff_pkg_install cmake g++ make git >/dev/null 2>&1
        local temp_build="/tmp/badvpn_build"
        rm -rf "$temp_build"
        git clone -q https://github.com/ambrop72/badvpn.git "$temp_build"
        (cd "$temp_build" && cmake . >/dev/null 2>&1 && make >/dev/null 2>&1)
        local compiled_bin=$(find "$temp_build" -name "badvpn-udpgw" -type f | head -n 1)
        if [[ -n "$compiled_bin" && -f "$compiled_bin" ]]; then
            cp "$compiled_bin" "$UDPGW_BINARY"
            chmod +x "$UDPGW_BINARY"
        else
            echo -e "\n${C_RED}❌ Failed to compile udpgw helper for $arch.${C_RESET}"
            rm -rf "$UDP_CUSTOM_DIR" "$temp_build"
            return
        fi
        rm -rf "$temp_build"
    fi

    echo -e "\n${C_GREEN}📝 Creating default config.json...${C_RESET}"
    cat > "$UDP_CUSTOM_DIR/config.json" <<EOF
{
  "listen": ":36712",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
EOF
    chmod 644 "$UDP_CUSTOM_DIR/config.json"

    echo -e "\n${C_GREEN}📝 Creating udpgw systemd service file...${C_RESET}"
    cat > "$UDPGW_SERVICE_FILE" <<EOF
[Unit]
Description=visibleTech UDPGW Backend
After=network.target

[Service]
User=root
Type=simple
ExecStart=$UDPGW_BINARY --listen-addr 127.0.0.1:7800 --max-clients 1000 --max-connections-for-client 100
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n${C_GREEN}📝 Creating systemd service file...${C_RESET}"
    cat > "$UDP_CUSTOM_SERVICE_FILE" <<EOF
[Unit]
Description=UDP Custom by visibleTech
After=network.target

[Service]
User=root
Type=simple
ExecStart=$UDP_CUSTOM_DIR/udp-custom server
WorkingDirectory=$UDP_CUSTOM_DIR/
Restart=always
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n${C_GREEN}▶️ Enabling and starting udp-custom service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable udpgw.service
    systemctl start udpgw.service
    systemctl enable udp-custom.service
    systemctl start udp-custom.service
    sleep 2
    if systemctl is-active --quiet udpgw && systemctl is-active --quiet udp-custom; then
        echo -e "\n${C_GREEN}✅ SUCCESS: udp-custom is installed and active.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: udp-custom service failed to start.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Displaying last 15 lines of the udp-custom and udpgw logs for diagnostics:${C_RESET}"
        journalctl -u udp-custom.service -n 15 --no-pager
        journalctl -u udpgw.service -n 15 --no-pager
    fi
}

uninstall_udp_custom() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling udp-custom ---${C_RESET}"
    if [ ! -f "$UDP_CUSTOM_SERVICE_FILE" ] && [ ! -f "$UDPGW_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ udp-custom is not installed, skipping.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Stopping and disabling udpgw service...${C_RESET}"
    systemctl stop udpgw.service >/dev/null 2>&1
    systemctl disable udpgw.service >/dev/null 2>&1
    echo -e "${C_GREEN}🛑 Stopping and disabling udp-custom service...${C_RESET}"
    systemctl stop udp-custom.service >/dev/null 2>&1
    systemctl disable udp-custom.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Removing systemd service file...${C_RESET}"
    rm -f "$UDP_CUSTOM_SERVICE_FILE"
    rm -f "$UDPGW_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Removing udp-custom directory and files...${C_RESET}"
    rm -rf "$UDP_CUSTOM_DIR"
    rm -f "$UDPGW_BINARY"
    echo -e "${C_GREEN}✅ udp-custom has been uninstalled successfully.${C_RESET}"
}


ensure_badvpn_service_is_quiet() {
    if [[ ! -f "$BADVPN_SERVICE_FILE" ]] || grep -q "^StandardOutput=null$" "$BADVPN_SERVICE_FILE" 2>/dev/null; then
        return
    fi

    local tmp_service
    tmp_service=$(mktemp)
    awk '
        /^\[Service\]$/ {
            print
            print "StandardOutput=null"
            print "StandardError=null"
            next
        }
        { print }
    ' "$BADVPN_SERVICE_FILE" > "$tmp_service" && mv "$tmp_service" "$BADVPN_SERVICE_FILE"
    rm -f "$tmp_service" 2>/dev/null
    systemctl daemon-reload
    systemctl restart badvpn.service >/dev/null 2>&1 || true
}

install_badvpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing badvpn (udpgw) ---${C_RESET}"
    if [ -f "$BADVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ badvpn is already installed.${C_RESET}"
        return
    fi
    check_and_open_firewall_port 7300 udp || return
    echo -e "\n${C_GREEN}🔄 Updating package lists...${C_RESET}"
    ff_apt_update || return
    echo -e "\n${C_GREEN}📦 Installing all required packages...${C_RESET}"
    ff_pkg_install cmake g++ make screen git build-essential libssl-dev libnspr4-dev libnss3-dev pkg-config || {
        echo -e "${C_RED}❌ Failed to install badvpn build dependencies.${C_RESET}"
        return
    }
    echo -e "\n${C_GREEN}📥 Cloning badvpn from github...${C_RESET}"
    git clone https://github.com/ambrop72/badvpn.git "$BADVPN_BUILD_DIR"
    cd "$BADVPN_BUILD_DIR" || { echo -e "${C_RED}❌ Failed to change directory to build folder.${C_RESET}"; return; }
    echo -e "\n${C_GREEN}⚙️ Running CMake...${C_RESET}"
    cmake . || { echo -e "${C_RED}❌ CMake configuration failed.${C_RESET}"; rm -rf "$BADVPN_BUILD_DIR"; return; }
    echo -e "\n${C_GREEN}🛠️ Compiling source...${C_RESET}"
    make || { echo -e "${C_RED}❌ Compilation (make) failed.${C_RESET}"; rm -rf "$BADVPN_BUILD_DIR"; return; }
    local badvpn_binary
    badvpn_binary=$(find "$BADVPN_BUILD_DIR" -name "badvpn-udpgw" -type f | head -n 1)
    if [[ -z "$badvpn_binary" || ! -f "$badvpn_binary" ]]; then
        echo -e "${C_RED}❌ ERROR: Could not find the compiled 'badvpn-udpgw' binary after compilation.${C_RESET}"
        rm -rf "$BADVPN_BUILD_DIR"
        return
    fi
    echo -e "${C_GREEN}ℹ️ Found binary at: $badvpn_binary${C_RESET}"
    chmod +x "$badvpn_binary"
    echo -e "\n${C_GREEN}📝 Creating systemd service file...${C_RESET}"
    cat > "$BADVPN_SERVICE_FILE" <<-EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target
[Service]
ExecStart=$badvpn_binary --listen-addr 0.0.0.0:7300 --max-clients 1000 --max-connections-for-client 8
User=root
Restart=always
RestartSec=3
StandardOutput=null
StandardError=null
[Install]
WantedBy=multi-user.target
EOF
    echo -e "\n${C_GREEN}▶️ Enabling and starting badvpn service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable badvpn.service
    systemctl start badvpn.service
    sleep 2
    if systemctl is-active --quiet badvpn; then
        echo -e "\n${C_GREEN}✅ SUCCESS: badvpn (udpgw) is installed and active on port 7300.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: badvpn service failed to start.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Displaying last 15 lines of the service log for diagnostics:${C_RESET}"
        journalctl -u badvpn.service -n 15 --no-pager
    fi
}

uninstall_badvpn() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling badvpn (udpgw) ---${C_RESET}"
    if [ ! -f "$BADVPN_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ badvpn is not installed, skipping.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Stopping and disabling badvpn service...${C_RESET}"
    systemctl stop badvpn.service >/dev/null 2>&1
    systemctl disable badvpn.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Removing systemd service file...${C_RESET}"
    rm -f "$BADVPN_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Removing badvpn build directory...${C_RESET}"
    rm -rf "$BADVPN_BUILD_DIR"
    echo -e "${C_GREEN}✅ badvpn has been uninstalled successfully.${C_RESET}"
}

# ====================================================================
# --- WebSocket Proxy & Stunnel (SSL/TLS) ---
# Works on Ubuntu 18.04 -> 26.04 and all Debian releases.
# ====================================================================

_cfg_get() {
    # usage: _cfg_get <file> <KEY>   (reads KEY="value" lines without sourcing)
    [[ -f "$1" ]] || return 0
    grep -m1 "^$2=" "$1" 2>/dev/null | cut -d'"' -f2
}

detect_preferred_host() {
    local host_domain=""
    host_domain=$(_cfg_get "$STUNNEL_INFO_FILE" ST_CERT_DOMAIN)
    if [[ -z "$host_domain" && -f "$DNS_INFO_FILE" ]]; then
        host_domain=$(grep 'FULL_DOMAIN' "$DNS_INFO_FILE" | cut -d'"' -f2)
    fi
    if [[ -z "$host_domain" ]]; then
        host_domain=$(curl -s -4 icanhazip.com)
    fi
    echo "$host_domain"
}

detect_ssh_port() {
    local p
    p=$(grep -hiE '^[[:space:]]*Port[[:space:]]+[0-9]+' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null | awk '{print $2}' | head -n 1)
    echo "${p:-22}"
}

_valid_port() {
    [[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 && $1 <= 65535 ))
}

_install_certbot() {
    if command -v certbot &> /dev/null; then
        echo -e "${C_GREEN}✅ Certbot is already installed.${C_RESET}"
        return 0
    fi
    echo -e "${C_BLUE}📦 Installing Certbot...${C_RESET}"
    ff_pkg_install certbot || {
        echo -e "${C_RED}❌ Failed to install Certbot.${C_RESET}"
        return 1
    }
    echo -e "${C_GREEN}✅ Certbot installed successfully.${C_RESET}"
    return 0
}

# --- WebSocket proxy -------------------------------------------------

write_websocket_script() {
    cat > "$WS_SCRIPT" <<'PYEOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# visibleTech WebSocket -> SSH proxy
# Pure standard library, works on Python 3.5 up to 3.14 (Ubuntu 18.04 - 26.04, all Debian).
#
# Behaviour:
#   * HTTP "Upgrade: websocket" style payloads (GET/POST/PATCH/CONNECT/... any method)
#     are answered with "101 Switching Protocols" (or "200 Connection established"
#     for CONNECT) and the connection is then relayed to the local SSH server.
#   * Split payloads (several HTTP header blocks in a row) are handled.
#   * Clients that send nothing (plain SSH, waits for the banner) or start with
#     "SSH-" are relayed straight to SSH.
#   * The destination is always the configured target - X-Real-Host is ignored.
import argparse
import base64
import hashlib
import re
import select
import socket
import sys
import threading
import time

BUFLEN = 65536
FIRST_WAIT = 2.0
MAX_HEADER = 16384
WS_GUID = b'258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
HTTP_REQ = re.compile(br'^[A-Za-z][A-Za-z\-]{1,20} \S+ HTTP/\d\.\d\r?\n')


def split_http(buf):
    """Return (header_block, rest) or None when the header block is incomplete."""
    best = None
    for sep in (b'\r\n\r\n', b'\n\n'):
        i = buf.find(sep)
        if i != -1 and (best is None or i < best[0]):
            best = (i, len(sep))
    if best is None:
        return None
    end = best[0] + best[1]
    return buf[:end], buf[end:]


def build_response(head):
    first = head.split(b'\n', 1)[0].strip()
    if first.upper().startswith(b'CONNECT '):
        return b'HTTP/1.1 200 Connection established\r\n\r\n'
    key = None
    for line in head.split(b'\n')[1:]:
        name, _, value = line.partition(b':')
        if name.strip().lower() == b'sec-websocket-key':
            key = value.strip()
    resp = (b'HTTP/1.1 101 Switching Protocols\r\n'
            b'Upgrade: websocket\r\n'
            b'Connection: Upgrade\r\n')
    if key:
        accept = base64.b64encode(hashlib.sha1(key + WS_GUID).digest())
        resp += b'Sec-WebSocket-Accept: ' + accept + b'\r\n'
    return resp + b'\r\n'


def scrub(client, state, data):
    """Drop stray HTTP header blocks that arrive before the SSH stream starts."""
    if not state['pre']:
        return data
    data = state['hold'] + data
    state['hold'] = b''
    while data:
        if data.startswith(b'SSH-'):
            state['pre'] = False
            return data
        if HTTP_REQ.match(data):
            parts = split_http(data)
            if parts is None:
                if len(data) > MAX_HEADER:
                    state['pre'] = False
                    return data
                state['hold'] = data
                return b''
            head, data = parts
            client.sendall(build_response(head))
            continue
        state['pre'] = False
        return data
    return b''


def relay(client, remote, first):
    state = {'pre': True, 'hold': b''}
    socks = [client, remote]
    if first:
        data = scrub(client, state, first)
        if data:
            remote.sendall(data)
    while True:
        readable, _, errored = select.select(socks, [], socks, 300)
        if errored:
            return
        for s in readable:
            data = s.recv(BUFLEN)
            if not data:
                return
            if s is client:
                data = scrub(client, state, data)
                if data:
                    remote.sendall(data)
            else:
                client.sendall(data)


def handle(client, target):
    remote = None
    try:
        client.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        client.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        buf = b''
        if select.select([client], [], [], FIRST_WAIT)[0]:
            buf = client.recv(BUFLEN)
            if not buf:
                return
        pending = buf
        if buf and HTTP_REQ.match(buf):
            while True:
                parts = split_http(buf)
                if parts is not None:
                    break
                if len(buf) > MAX_HEADER:
                    return
                if not select.select([client], [], [], 5)[0]:
                    return
                more = client.recv(BUFLEN)
                if not more:
                    return
                buf += more
            head, pending = parts
            client.sendall(build_response(head))
        remote = socket.create_connection(target, 10)
        remote.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        remote.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        relay(client, remote, pending)
    except Exception:
        pass
    finally:
        for s in (client, remote):
            if s is not None:
                try:
                    s.close()
                except Exception:
                    pass


def open_listener(port):
    candidates = [(socket.AF_INET6, '::'), (socket.AF_INET, '0.0.0.0')]
    last_err = None
    for family, addr in candidates:
        s = None
        try:
            s = socket.socket(family, socket.SOCK_STREAM)
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            if family == socket.AF_INET6:
                s.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
            s.bind((addr, port))
            s.listen(1024)
            return s
        except Exception as exc:
            last_err = exc
            if s is not None:
                s.close()
    raise last_err


def accept_loop(listener, target):
    while True:
        try:
            client, _ = listener.accept()
        except Exception:
            time.sleep(0.2)
            continue
        t = threading.Thread(target=handle, args=(client, target))
        t.daemon = True
        t.start()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ports', required=True, help='comma separated listen ports')
    parser.add_argument('--target', default='127.0.0.1:22', help='host:port of the SSH server')
    args = parser.parse_args()

    host, _, port = args.target.rpartition(':')
    target = (host or '127.0.0.1', int(port))
    ports = [int(p) for p in args.ports.replace(' ', ',').split(',') if p]

    listeners = []
    for p in ports:
        listeners.append(open_listener(p))
    for lst in listeners:
        t = threading.Thread(target=accept_loop, args=(lst, target))
        t.daemon = True
        t.start()
    while True:
        time.sleep(3600)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
PYEOF
    chmod 755 "$WS_SCRIPT"
}

install_websocket() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Installing WebSocket Proxy (HTTP Upgrade -> SSH) ---${C_RESET}"

    if [ -f "$WS_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ WebSocket proxy is already installed.${C_RESET}"
        echo -e "   Port(s): ${C_YELLOW}$(_cfg_get "$WS_CONFIG_FILE" WS_PORTS)${C_RESET}  ->  SSH port ${C_YELLOW}$(_cfg_get "$WS_CONFIG_FILE" WS_TARGET_PORT)${C_RESET}"
        read -p "👉 Do you want to reinstall/reconfigure? (y/n): " confirm_reinstall
        if [[ "$confirm_reinstall" != "y" && "$confirm_reinstall" != "Y" ]]; then return; fi
    fi

    if ! command -v python3 &>/dev/null; then
        echo -e "\n${C_BLUE}📦 Installing python3...${C_RESET}"
        ff_pkg_install python3 || { echo -e "${C_RED}❌ Failed to install python3.${C_RESET}"; return; }
    fi
    if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 5) else 1)' 2>/dev/null; then
        echo -e "${C_RED}❌ Python 3.5 or newer is required.${C_RESET}"
        return
    fi
    local py_bin
    py_bin=$(command -v python3)

    local ports ssh_port default_ssh
    default_ssh=$(detect_ssh_port)
    read -p "👉 Enter WebSocket port(s) (e.g. 80 or 80 8080) [80]: " ports
    ports=${ports:-80}
    read -p "👉 SSH port to forward to [$default_ssh]: " ssh_port
    ssh_port=${ssh_port:-$default_ssh}

    _valid_port "$ssh_port" || { echo -e "\n${C_RED}❌ Invalid SSH port: $ssh_port${C_RESET}"; return; }
    local -a port_array=()
    local port
    for port in $ports; do
        if ! _valid_port "$port"; then
            echo -e "\n${C_RED}❌ Invalid port number: $port. Aborting.${C_RESET}"
            return
        fi
        port_array+=("$port")
    done
    (( ${#port_array[@]} > 0 )) || { echo -e "\n${C_RED}❌ No port given.${C_RESET}"; return; }

    # Free our own ports first when reinstalling
    systemctl stop "$WS_SERVICE_NAME" >/dev/null 2>&1

    for port in "${port_array[@]}"; do
        check_and_free_ports "$port" || return
        check_and_open_firewall_port "$port" tcp || return
    done

    echo -e "\n${C_GREEN}📝 Installing WebSocket proxy script...${C_RESET}"
    write_websocket_script

    local port_csv
    port_csv=$(IFS=,; echo "${port_array[*]}")

    echo -e "${C_GREEN}📝 Creating systemd service...${C_RESET}"
    cat > "$WS_SERVICE_FILE" <<EOF
[Unit]
Description=visibleTech WebSocket Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=$py_bin $WS_SCRIPT --ports $port_csv --target 127.0.0.1:$ssh_port
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    mkdir -p "$DB_DIR"
    cat > "$WS_CONFIG_FILE" <<EOF
WS_PORTS="${port_array[*]}"
WS_TARGET_PORT="$ssh_port"
EOF

    systemctl daemon-reload
    systemctl enable "$WS_SERVICE_NAME" >/dev/null 2>&1
    systemctl restart "$WS_SERVICE_NAME"
    sleep 2

    if systemctl is-active --quiet "$WS_SERVICE_NAME"; then
        echo -e "\n${C_GREEN}✅ SUCCESS: WebSocket proxy is active.${C_RESET}"
        echo -e "   • Listening on port(s): ${C_YELLOW}${port_array[*]}${C_RESET}"
        echo -e "   • Forwarding to SSH:    ${C_YELLOW}127.0.0.1:$ssh_port${C_RESET}"
        echo -e "   • Payload example:      ${C_WHITE}GET / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf][crlf]${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: WebSocket proxy failed to start.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Last 15 lines of the service log:${C_RESET}"
        journalctl -u "$WS_SERVICE_NAME" -n 15 --no-pager
    fi
}

uninstall_websocket() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling WebSocket Proxy ---${C_RESET}"
    if [ ! -f "$WS_SERVICE_FILE" ] && [ ! -f "$WS_SCRIPT" ]; then
        echo -e "${C_YELLOW}ℹ️ WebSocket proxy is not installed, skipping.${C_RESET}"
        return
    fi
    if [[ "$(_cfg_get "$STUNNEL_INFO_FILE" ST_TARGET)" == WebSocket* ]]; then
        echo -e "${C_YELLOW}⚠️ Stunnel is forwarding to the WebSocket proxy. Reinstall Stunnel (option 9) and pick SSH as the target afterwards.${C_RESET}"
    fi
    echo -e "${C_GREEN}🛑 Stopping and disabling WebSocket proxy...${C_RESET}"
    systemctl stop "$WS_SERVICE_NAME" >/dev/null 2>&1
    systemctl disable "$WS_SERVICE_NAME" >/dev/null 2>&1
    rm -f "$WS_SERVICE_FILE" "$WS_SCRIPT" "$WS_CONFIG_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ WebSocket proxy has been uninstalled.${C_RESET}"
}

# --- Stunnel (SSL/TLS) -------------------------------------------------

generate_self_signed_cert() {
    local common_name="$1"
    mkdir -p "$SSL_CERT_DIR"
    echo -e "\n${C_GREEN}🔐 Generating a self-signed certificate...${C_RESET}"
    openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout "$SSL_CERT_KEY_FILE" \
        -out "$SSL_CERT_CHAIN_FILE" \
        -subj "/CN=$common_name" \
        >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to generate the self-signed certificate.${C_RESET}"
            return 1
        }
    chmod 644 "$SSL_CERT_CHAIN_FILE"
    chmod 600 "$SSL_CERT_KEY_FILE"
    ST_CERT_MODE="self-signed"; ST_CERT_DOMAIN="$common_name"; ST_CERT_EMAIL=""
    echo -e "${C_GREEN}✅ Certificate created for ${C_YELLOW}$common_name${C_RESET}"
    return 0
}

obtain_certbot_cert() {
    local domain_name="$1"
    local email="$2"
    local ws_was_active=0

    mkdir -p "$SSL_CERT_DIR"
    _install_certbot || return 1

    if systemctl is-active --quiet "$WS_SERVICE_NAME"; then
        ws_was_active=1
        echo -e "\n${C_BLUE}🛑 Pausing WebSocket proxy for Certbot validation...${C_RESET}"
        systemctl stop "$WS_SERVICE_NAME" >/dev/null 2>&1
        sleep 1
    fi

    check_and_free_ports 80 || {
        [[ "$ws_was_active" -eq 1 ]] && systemctl start "$WS_SERVICE_NAME" >/dev/null 2>&1
        return 1
    }
    check_and_open_firewall_port 80 tcp

    echo -e "\n${C_BLUE}🚀 Requesting a Certbot certificate for ${C_YELLOW}$domain_name${C_RESET}"
    certbot certonly --standalone -d "$domain_name" --non-interactive --agree-tos -m "$email"
    local rc=$?
    [[ "$ws_was_active" -eq 1 ]] && systemctl start "$WS_SERVICE_NAME" >/dev/null 2>&1
    if [ $rc -ne 0 ]; then
        echo -e "\n${C_RED}❌ Certbot failed to obtain a certificate.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Make sure the domain points to this server and port 80 is reachable.${C_RESET}"
        return 1
    fi

    local certbot_chain="/etc/letsencrypt/live/$domain_name/fullchain.pem"
    local certbot_key="/etc/letsencrypt/live/$domain_name/privkey.pem"
    if [ ! -f "$certbot_chain" ] || [ ! -f "$certbot_key" ]; then
        echo -e "\n${C_RED}❌ Certbot completed, but the certificate files were not found.${C_RESET}"
        return 1
    fi

    cp "$certbot_chain" "$SSL_CERT_CHAIN_FILE"
    cp "$certbot_key" "$SSL_CERT_KEY_FILE"
    chmod 644 "$SSL_CERT_CHAIN_FILE"
    chmod 600 "$SSL_CERT_KEY_FILE"

    # Keep the copied certificate fresh when Certbot renews it
    mkdir -p "$(dirname "$STUNNEL_RENEW_HOOK")"
    cat > "$STUNNEL_RENEW_HOOK" <<EOF
#!/bin/bash
if [ "\$RENEWED_LINEAGE" = "/etc/letsencrypt/live/$domain_name" ]; then
    cp "\$RENEWED_LINEAGE/fullchain.pem" "$SSL_CERT_CHAIN_FILE"
    cp "\$RENEWED_LINEAGE/privkey.pem" "$SSL_CERT_KEY_FILE"
    chmod 644 "$SSL_CERT_CHAIN_FILE"
    chmod 600 "$SSL_CERT_KEY_FILE"
    systemctl restart $STUNNEL_SERVICE_NAME 2>/dev/null
fi
EOF
    chmod 755 "$STUNNEL_RENEW_HOOK"

    ST_CERT_MODE="certbot"; ST_CERT_DOMAIN="$domain_name"; ST_CERT_EMAIL="$email"
    echo -e "${C_GREEN}✅ Certbot certificate copied into ${C_YELLOW}$SSL_CERT_DIR${C_RESET}"
    return 0
}

select_stunnel_certificate() {
    local preferred_host cert_choice
    local has_existing_cert=false

    preferred_host=$(detect_preferred_host)
    [[ -z "$preferred_host" ]] && preferred_host="visibleTech.local"

    if [ -s "$SSL_CERT_CHAIN_FILE" ] && [ -s "$SSL_CERT_KEY_FILE" ]; then
        has_existing_cert=true
    fi

    echo -e "\n${C_BOLD}${C_PURPLE}--- 🔐 TLS Certificate ---${C_RESET}"
    if $has_existing_cert; then
        ST_CERT_MODE=$(_cfg_get "$STUNNEL_INFO_FILE" ST_CERT_MODE)
        ST_CERT_DOMAIN=$(_cfg_get "$STUNNEL_INFO_FILE" ST_CERT_DOMAIN)
        ST_CERT_EMAIL=$(_cfg_get "$STUNNEL_INFO_FILE" ST_CERT_EMAIL)
        [[ -z "$ST_CERT_MODE" ]] && ST_CERT_MODE="existing"
        printf "  ${C_CHOICE}[ 1]${C_RESET} %s\n" "Reuse existing certificate (${ST_CERT_MODE}${ST_CERT_DOMAIN:+ - $ST_CERT_DOMAIN})"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %s\n" "Replace with a new self-signed certificate"
        printf "  ${C_CHOICE}[ 3]${C_RESET} %s\n" "Replace with a Let's Encrypt (Certbot) certificate"
    else
        printf "  ${C_CHOICE}[ 1]${C_RESET} %s\n" "Generate a self-signed certificate"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %s\n" "Use a Let's Encrypt (Certbot) certificate"
    fi
    echo
    read -p "👉 Enter choice [1]: " cert_choice
    cert_choice=${cert_choice:-1}

    local want=""
    if $has_existing_cert; then
        case "$cert_choice" in
            1) echo -e "${C_GREEN}✅ Reusing the existing certificate.${C_RESET}"; return 0 ;;
            2) want="self" ;;
            3) want="certbot" ;;
            *) echo -e "${C_RED}❌ Invalid option.${C_RESET}"; return 1 ;;
        esac
    else
        case "$cert_choice" in
            1) want="self" ;;
            2) want="certbot" ;;
            *) echo -e "${C_RED}❌ Invalid option.${C_RESET}"; return 1 ;;
        esac
    fi

    if [[ "$want" == "self" ]]; then
        local common_name
        read -p "👉 Enter the certificate Common Name / SNI label [$preferred_host]: " common_name
        common_name=${common_name:-$preferred_host}
        generate_self_signed_cert "$common_name"
        return $?
    fi

    local default_domain="" domain_name email
    if ! _is_valid_ipv4 "$preferred_host"; then default_domain="$preferred_host"; fi
    if [[ -n "$default_domain" ]]; then
        read -p "👉 Enter your domain name [$default_domain]: " domain_name
        domain_name=${domain_name:-$default_domain}
    else
        read -p "👉 Enter your domain name (e.g. vpn.example.com): " domain_name
    fi
    if [[ -z "$domain_name" ]]; then
        echo -e "${C_RED}❌ Domain name cannot be empty.${C_RESET}"; return 1
    fi
    if _is_valid_ipv4 "$domain_name"; then
        echo -e "${C_RED}❌ Certbot requires a real domain name, not a raw IP address.${C_RESET}"; return 1
    fi
    read -p "👉 Enter your email for Let's Encrypt [${ST_CERT_EMAIL}]: " email
    email=${email:-$ST_CERT_EMAIL}
    if [[ -z "$email" ]]; then
        echo -e "${C_RED}❌ Email cannot be empty.${C_RESET}"; return 1
    fi
    obtain_certbot_cert "$domain_name" "$email"
}

install_stunnel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔒 Installing Stunnel (SSL/TLS Tunnel) ---${C_RESET}"

    if [ -f "$STUNNEL_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ Stunnel is already installed.${C_RESET}"
        echo -e "   TLS port: ${C_YELLOW}$(_cfg_get "$STUNNEL_INFO_FILE" ST_PORT)${C_RESET}  ->  ${C_YELLOW}$(_cfg_get "$STUNNEL_INFO_FILE" ST_TARGET)${C_RESET}"
        read -p "👉 Do you want to reinstall/reconfigure? (y/n): " confirm_reinstall
        if [[ "$confirm_reinstall" != "y" && "$confirm_reinstall" != "Y" ]]; then return; fi
    fi

    echo -e "\n${C_BLUE}📦 Installing stunnel4 and openssl...${C_RESET}"
    ff_pkg_install stunnel4 openssl || {
        echo -e "${C_RED}❌ Failed to install stunnel4.${C_RESET}"
        return
    }
    local stunnel_bin
    stunnel_bin=$(command -v stunnel4 || command -v stunnel)
    if [[ -z "$stunnel_bin" ]]; then
        echo -e "${C_RED}❌ stunnel binary not found after installation.${C_RESET}"
        return
    fi

    local st_port
    read -p "👉 Enter the TLS port for Stunnel [443]: " st_port
    st_port=${st_port:-443}
    _valid_port "$st_port" || { echo -e "\n${C_RED}❌ Invalid port: $st_port${C_RESET}"; return; }

    local ssh_port ws_first_port target_mode target_label target_port
    ssh_port=$(detect_ssh_port)
    ws_first_port=$(_cfg_get "$WS_CONFIG_FILE" WS_PORTS | awk '{print $1}')

    echo -e "\n${C_CYAN}Where should Stunnel forward decrypted traffic?${C_RESET}"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %s\n" "SSH directly (127.0.0.1:${ssh_port})  - SSL/TLS + SNI"
    if [[ -n "$ws_first_port" ]] && systemctl is-active --quiet "$WS_SERVICE_NAME"; then
        printf "  ${C_CHOICE}[ 2]${C_RESET} %s\n" "WebSocket proxy (127.0.0.1:${ws_first_port}) - SSL + WebSocket payload"
    else
        printf "  ${C_CHOICE}[ 2]${C_RESET} %s\n" "WebSocket proxy ${C_DIM}(install the WebSocket proxy first)${C_RESET}"
    fi
    read -p "👉 Enter choice [1]: " target_mode
    target_mode=${target_mode:-1}
    case "$target_mode" in
        1) target_port="$ssh_port"; target_label="SSH" ;;
        2)
            if [[ -z "$ws_first_port" ]] || ! systemctl is-active --quiet "$WS_SERVICE_NAME"; then
                echo -e "\n${C_RED}❌ The WebSocket proxy is not running. Install it first (Protocol Manager option 5).${C_RESET}"
                return
            fi
            target_port="$ws_first_port"; target_label="WebSocket"
            ;;
        *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"; return ;;
    esac

    # Free our own port first when reinstalling
    systemctl stop "$STUNNEL_SERVICE_NAME" >/dev/null 2>&1
    check_and_free_ports "$st_port" || return
    check_and_open_firewall_port "$st_port" tcp || return

    ST_CERT_MODE=""; ST_CERT_DOMAIN=""; ST_CERT_EMAIL=""
    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$STUNNEL_DIR"
    select_stunnel_certificate || return

    echo -e "\n${C_GREEN}📝 Writing Stunnel configuration...${C_RESET}"
    cat > "$STUNNEL_CONF" <<EOF
; visibleTech Stunnel configuration
foreground = yes
pid =
cert = $SSL_CERT_CHAIN_FILE
key = $SSL_CERT_KEY_FILE
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
TIMEOUTidle = 86400

[ssh-tls]
accept = $st_port
connect = 127.0.0.1:$target_port
EOF
    chmod 600 "$STUNNEL_CONF"

    echo -e "${C_GREEN}📝 Creating systemd service...${C_RESET}"
    cat > "$STUNNEL_SERVICE_FILE" <<EOF
[Unit]
Description=visibleTech Stunnel (SSL/TLS tunnel)
After=network.target

[Service]
Type=simple
User=root
ExecStart=$stunnel_bin $STUNNEL_CONF
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    cat > "$STUNNEL_INFO_FILE" <<EOF
ST_PORT="$st_port"
ST_TARGET="$target_label 127.0.0.1:$target_port"
ST_CERT_MODE="$ST_CERT_MODE"
ST_CERT_DOMAIN="$ST_CERT_DOMAIN"
ST_CERT_EMAIL="$ST_CERT_EMAIL"
EOF

    # Older Debian/Ubuntu init scripts only start stunnel when ENABLED=1
    [ -f /etc/default/stunnel4 ] && sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4 2>/dev/null

    systemctl daemon-reload
    systemctl enable "$STUNNEL_SERVICE_NAME" >/dev/null 2>&1
    systemctl restart "$STUNNEL_SERVICE_NAME"
    sleep 2

    if systemctl is-active --quiet "$STUNNEL_SERVICE_NAME"; then
        echo -e "\n${C_GREEN}✅ SUCCESS: Stunnel is active.${C_RESET}"
        echo -e "   • TLS port:     ${C_YELLOW}$st_port${C_RESET}"
        echo -e "   • Forwards to:  ${C_YELLOW}$target_label (127.0.0.1:$target_port)${C_RESET}"
        echo -e "   • Certificate:  ${C_YELLOW}${ST_CERT_MODE}${ST_CERT_DOMAIN:+ - $ST_CERT_DOMAIN}${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: Stunnel failed to start.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Last 15 lines of the service log:${C_RESET}"
        journalctl -u "$STUNNEL_SERVICE_NAME" -n 15 --no-pager
    fi
}

uninstall_stunnel() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling Stunnel ---${C_RESET}"
    if [ ! -f "$STUNNEL_SERVICE_FILE" ] && [ ! -f "$STUNNEL_CONF" ]; then
        echo -e "${C_YELLOW}ℹ️ Stunnel is not installed, skipping.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Stopping and disabling Stunnel...${C_RESET}"
    systemctl stop "$STUNNEL_SERVICE_NAME" >/dev/null 2>&1
    systemctl disable "$STUNNEL_SERVICE_NAME" >/dev/null 2>&1
    rm -f "$STUNNEL_SERVICE_FILE" "$STUNNEL_RENEW_HOOK"
    rm -rf "$STUNNEL_DIR"
    rm -f "$STUNNEL_INFO_FILE"
    systemctl daemon-reload

    local delete_cert="n" purge_pkg="n"
    if [[ "$UNINSTALL_MODE" == "silent" ]]; then
        delete_cert="y"; purge_pkg="y"
    else
        if [ -f "$SSL_CERT_CHAIN_FILE" ] || [ -f "$SSL_CERT_KEY_FILE" ]; then
            read -p "👉 Delete the TLS certificate too? (y/n): " delete_cert
        fi
        read -p "👉 Also remove the stunnel4 package? (y/n): " purge_pkg
    fi
    if [[ "$delete_cert" == "y" || "$delete_cert" == "Y" ]]; then
        rm -f "$SSL_CERT_CHAIN_FILE" "$SSL_CERT_KEY_FILE"
        echo -e "${C_GREEN}🗑️ Certificate files removed.${C_RESET}"
    fi
    if [[ "$purge_pkg" == "y" || "$purge_pkg" == "Y" ]]; then
        ff_pkg_purge stunnel4 >/dev/null 2>&1
        ff_pkg_autoremove
        echo -e "${C_GREEN}🗑️ stunnel4 package removed.${C_RESET}"
    fi
    echo -e "${C_GREEN}✅ Stunnel has been uninstalled.${C_RESET}"
}

# --- Shared info / management menu ---------------------------------------

print_tunnel_endpoints() {
    local host="$1"
    if systemctl is-active --quiet "$WS_SERVICE_NAME"; then
        local ws_ports
        ws_ports=$(_cfg_get "$WS_CONFIG_FILE" WS_PORTS)
        echo -e "\n🔹 ${C_BOLD}WebSocket (HTTP Upgrade -> SSH)${C_RESET}:"
        echo -e "   • Host: $host"
        echo -e "   • Port(s): ${ws_ports:-80}"
        echo -e "   • Payload: GET / HTTP/1.1[crlf]Host: [host][crlf]Upgrade: websocket[crlf][crlf]"
    fi
    if systemctl is-active --quiet "$STUNNEL_SERVICE_NAME"; then
        local st_port st_target
        st_port=$(_cfg_get "$STUNNEL_INFO_FILE" ST_PORT)
        st_target=$(_cfg_get "$STUNNEL_INFO_FILE" ST_TARGET)
        echo -e "\n🔹 ${C_BOLD}SSL/TLS (Stunnel)${C_RESET}:"
        echo -e "   • Host: $host"
        echo -e "   • Port: ${st_port:-443}"
        echo -e "   • SNI (BugHost): $host (or your preferred SNI)"
        echo -e "   • Forwards to: ${st_target:-SSH}"
    fi
}

ws_stunnel_menu() {
    while true; do
        show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- ⚙️ WebSocket & Stunnel Management ---${C_RESET}"
        local ws_s="${C_STATUS_I}Inactive${C_RESET}" st_s="${C_STATUS_I}Inactive${C_RESET}"
        systemctl is-active --quiet "$WS_SERVICE_NAME" && ws_s="${C_STATUS_A}Active${C_RESET}"
        systemctl is-active --quiet "$STUNNEL_SERVICE_NAME" && st_s="${C_STATUS_A}Active${C_RESET}"
        echo -e "\n${C_WHITE}WebSocket:${C_RESET} ${ws_s}"
        echo -e "${C_WHITE}Stunnel:${C_RESET}   ${st_s}"
        echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
        printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🔄 Restart WebSocket proxy"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "🔄 Restart Stunnel"
        printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "📜 WebSocket logs (last 30 lines)"
        printf "  ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "📜 Stunnel logs (last 30 lines)"
        printf "  ${C_CHOICE}[ 5]${C_RESET} %-40s\n" "📋 Show connection details"
        echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            return
        fi
        case $choice in
            1)
                if [ -f "$WS_SERVICE_FILE" ]; then
                    systemctl restart "$WS_SERVICE_NAME" && echo -e "\n${C_GREEN}✅ WebSocket proxy restarted.${C_RESET}" || echo -e "\n${C_RED}❌ Restart failed.${C_RESET}"
                else
                    echo -e "\n${C_YELLOW}ℹ️ WebSocket proxy is not installed.${C_RESET}"
                fi
                press_enter ;;
            2)
                if [ -f "$STUNNEL_SERVICE_FILE" ]; then
                    systemctl restart "$STUNNEL_SERVICE_NAME" && echo -e "\n${C_GREEN}✅ Stunnel restarted.${C_RESET}" || echo -e "\n${C_RED}❌ Restart failed.${C_RESET}"
                else
                    echo -e "\n${C_YELLOW}ℹ️ Stunnel is not installed.${C_RESET}"
                fi
                press_enter ;;
            3) echo; journalctl -u "$WS_SERVICE_NAME" -n 30 --no-pager; press_enter ;;
            4) echo; journalctl -u "$STUNNEL_SERVICE_NAME" -n 30 --no-pager; press_enter ;;
            5)
                local h
                h=$(detect_preferred_host)
                if systemctl is-active --quiet "$WS_SERVICE_NAME" || systemctl is-active --quiet "$STUNNEL_SERVICE_NAME"; then
                    print_tunnel_endpoints "$h"
                else
                    echo -e "\n${C_YELLOW}ℹ️ Neither WebSocket nor Stunnel is running.${C_RESET}"
                fi
                press_enter ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

# ====================================================================
# --- FastDns MODED (DNSTT + EDNS proxy + tuning) ---
# Installer, retune, extra tunnels and uninstall all come from the
# embedded moded.sh below. Binary and keys are fetched from the repo
# https://github.com/wavy07/manage ("DNSTT MODED" folder).
# ====================================================================

write_fastdns_moded_script() {
    mkdir -p "$FASTDNS_MODED_DIR"
    cat > "$FASTDNS_MODED_SCRIPT" <<'FF_FASTDNS_MODED_EOF'
#!/usr/bin/env bash
# =============================================================================
#   FASTDNS MODED INSTALLER  -  DNSTT + EDNS proxy (C) + MTU 1800 + tuning
# =============================================================================
#   Supports : Ubuntu 20.04 - 26.04, Debian 10 - 13 (and apt-based derivatives
#              such as Mint, Kali, Raspberry Pi OS)
#   Repo     : https://github.com/wavy07/manage  ->  "DNSTT MODED" folder
#   Files    : dnstt-server, server.key, server.pub, moded.sh
#
#   Run:
#     bash <(curl -fsSL "https://raw.githubusercontent.com/wavy07/manage/main/DNSTT%20MODED/moded.sh")
#   or non-interactive:
#     NS_DOMAIN=t.example.com bash moded.sh
#
#   Env options : NS_DOMAIN  SSHD_PORT(22)  FASTDNS_PORT(5300)  MTU(1800)
#                 EDNS_SIZE(1800)  WORKERS  FASTDNS_LISTEN(127.0.0.1)
#                 GITHUB_BASE  GITHUB_TOKEN(private repo)  NO_ANIM=1
#   Retune      : bash moded.sh --retune <MTU> [EDNS]   e.g. 1232, 1400, 1452, 1800
#   Tunnels     : bash moded.sh --add-tunnel t2.example.com   (more domains = more speed)
#                 bash moded.sh --tunnels | --remove-tunnel t2.example.com
#   Remove      : bash moded.sh --uninstall
# =============================================================================
set -uo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8

# ----------------------------------------------------------------- CONFIG
GITHUB_BASE="${GITHUB_BASE:-https://raw.githubusercontent.com/wavy07/manage/main/DNSTT%20MODED}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
SSHD_PORT="${SSHD_PORT:-22}"
FASTDNS_PORT="${FASTDNS_PORT:-5300}"
FASTDNS_LISTEN="${FASTDNS_LISTEN:-127.0.0.1}"
MTU="${MTU:-1800}"
EDNS_SIZE="${EDNS_SIZE:-1800}"
CORES="$(nproc 2>/dev/null || echo 1)"
WORKERS="${WORKERS:-$(( CORES > 4 ? 4 : CORES ))}"
NS_DOMAIN="${NS_DOMAIN:-}"

FASTDNS_DIR="/etc/fastdns"
PROXY_BIN="/usr/local/bin/edns-proxy"
SVC_USER="fastdns"
LOG_FILE="/var/log/fastdns-install.log"
CONTACT_LINE="${CONTACT_LINE:-Need help? Contact .inc🦜- +255 689000656}"

TOTAL_STEPS=7
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || SCRIPT_DIR="/nonexistent"
TMPD=""
CUR_PCT=0
W=56
T0=$SECONDS

# ----------------------------------------------------------------- COLORS / ANIMATION FLAGS
COLOR=0; ANIM=0
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then COLOR=1; fi
if (( COLOR )) && [[ "${NO_ANIM:-0}" != "1" ]]; then ANIM=1; fi

if (( COLOR )); then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'
  PURPLE=$'\033[0;35m'; CYAN=$'\033[0;36m'; WHITE=$'\033[1;37m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; PURPLE=''; CYAN=''; WHITE=''; BOLD=''; DIM=''; NC=''
fi
CR=''; EL=''
if (( ANIM )); then CR=$'\r'; EL=$'\033[K'; fi
SPIN_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

hide_cursor() { if (( ANIM )); then printf '\033[?25l'; fi; return 0; }
show_cursor() { if (( COLOR )); then printf '\033[?25h'; fi; return 0; }
nap()         { if (( ANIM )); then sleep "${1:-0.04}"; fi; return 0; }

# ----------------------------------------------------------------- DRAWING HELPERS
rep() { local s; printf -v s '%*s' "$2" ''; printf '%s' "${s// /$1}"; }
strip_ansi() { printf '%s' "$1" | sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

_edge() { printf '%s%s%s%s%s\n' "$1" "$2" "$(rep "$3" $((W-2)))" "$4" "$NC"; }
_line() {   # color vchar text
  local plain pad
  plain="$(strip_ansi "$3")"; pad=$(( W - 4 - ${#plain} )); (( pad < 0 )) && pad=0
  printf '%s%s%s %s%*s %s%s%s\n' "$1" "$2" "$NC" "$3" "$pad" "" "$1" "$2" "$NC"
}
_center() { # color vchar text
  local plain total left right
  plain="$(strip_ansi "$3")"; total=$(( W - 2 - ${#plain} )); (( total < 0 )) && total=0
  left=$(( total / 2 )); right=$(( total - left ))
  printf '%s%s%s%*s%s%*s%s%s%s\n' "$1" "$2" "$NC" "$left" "" "$3" "$right" "" "$1" "$2" "$NC"
}
bx_top() { _edge "$1" ┌ ─ ┐; }
bx_mid() { _edge "$1" ├ ─ ┤; }
bx_bot() { _edge "$1" └ ─ ┘; }
bx_row() { _line "$1" │ "$2"; }
dbx_top() { _edge "$1" ╔ ═ ╗; }
dbx_bot() { _edge "$1" ╚ ═ ╝; }
dbx_center() { _center "$1" ║ "$2"; }

log()  { printf '[%s] %s\n' "$(date '+%F %T')" "$*" >>"$LOG_FILE" 2>/dev/null; return 0; }
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$NC" "$*"; log "OK: $*"; }
bad()  { printf '  %s✗%s %s%s%s\n' "$RED" "$NC" "$RED" "$*" "$NC"; log "ERR: $*"; }
warn() { printf '  %s!%s %s%s%s\n' "$YELLOW" "$NC" "$YELLOW" "$*" "$NC"; log "WARN: $*"; }
info() { printf '  %sℹ%s %s%s%s\n' "$CYAN" "$NC" "$CYAN" "$*" "$NC"; }
die()  { show_cursor; echo; bad "$*"; printf '  %sLog: %s%s\n\n' "$DIM" "$LOG_FILE" "$NC"; exit 1; }

# animated progress bar (one line, redrawn in place)
draw_bar() {
  local pct=$1 w=24 f
  f=$(( pct * w / 100 ))
  printf '\r%s│%s  %s%s%s%s%s %3d%%\033[K' "$BLUE" "$NC" "$GREEN" "$(rep '█' "$f")" "$DIM" "$(rep '░' $((w - f)))" "$NC" "$pct"
}
animate_bar() {   # from to
  local p=$1 to=$2
  if (( ANIM )); then
    while (( p < to )); do p=$(( p + 2 )); (( p > to )) && p=$to; draw_bar "$p"; sleep 0.015; done
    draw_bar "$to"; echo
  else
    printf '|  progress %d%%\n' "$to"
  fi
}
step() {   # n title
  local n=$1 pct
  pct=$(( n * 100 / TOTAL_STEPS ))
  printf '\n%s┌─%s %s%sSTEP %s/%s%s  %s%s%s\n' "$BLUE" "$NC" "$CYAN" "$BOLD" "$n" "$TOTAL_STEPS" "$NC" "$WHITE" "$2" "$NC"
  log "STEP $n: $2"
  animate_bar "$CUR_PCT" "$pct"
  CUR_PCT=$pct
  echo "${BLUE}│${NC}"
}
step_end() { printf '%s└─%s %s✓%s Completed\n' "$BLUE" "$NC" "$GREEN" "$NC"; }

# run a command with a spinner; its output goes to the log file
spin_run() {   # label cmd...
  local label="$1"; shift
  local soft="${SPIN_SOFT:-0}" start=$SECONDS rc pid i=0 secs
  log "RUN: $label"
  if (( ANIM )); then
    ( "$@" ) >>"$LOG_FILE" 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r  %s%s%s %s %s(%ds)%s\033[K' "$CYAN" "${SPIN_FRAMES[i % 10]}" "$NC" "$label" "$DIM" $(( SECONDS - start )) "$NC"
      i=$(( i + 1 )); sleep 0.08
    done
    wait "$pid"; rc=$?
  else
    ( "$@" ) >>"$LOG_FILE" 2>&1; rc=$?
  fi
  secs=$(( SECONDS - start ))
  if (( rc == 0 )); then
    printf '%s  %s✓%s %s %s(%ds)%s%s\n' "$CR" "$GREEN" "$NC" "$label" "$DIM" "$secs" "$NC" "$EL"
  elif (( soft )); then
    printf '%s  %s!%s %s %s(skipped)%s%s\n' "$CR" "$YELLOW" "$NC" "$label" "$DIM" "$NC" "$EL"
  else
    printf '%s  %s✗%s %s%s%s%s\n' "$CR" "$RED" "$NC" "$RED" "$label" "$NC" "$EL"
    tail -n 8 "$LOG_FILE" 2>/dev/null | sed 's/^/      /'
  fi
  return "$rc"
}
spin_try() { SPIN_SOFT=1 spin_run "$@"; }

# poll a condition with a spinner
spin_wait() {   # label timeout cmd...
  local label="$1" t="$2"; shift 2
  local end=$(( SECONDS + t )) i=0
  while ! "$@" >/dev/null 2>&1; do
    if (( SECONDS >= end )); then
      printf '%s  %s✗%s %s%s%s%s\n' "$CR" "$RED" "$NC" "$RED" "$label" "$NC" "$EL"; return 1
    fi
    if (( ANIM )); then
      printf '\r  %s%s%s %s\033[K' "$CYAN" "${SPIN_FRAMES[i % 10]}" "$NC" "$label"
      i=$(( i + 1 )); sleep 0.1
    else
      sleep 0.4
    fi
  done
  printf '%s  %s✓%s %s%s\n' "$CR" "$GREEN" "$NC" "$label" "$EL"
}

banner() {
  if (( ANIM )); then clear; fi
  echo
  dbx_top "$BLUE";                                                        nap 0.05
  dbx_center "$BLUE" "${CYAN}${BOLD}FASTDNS  MODED  INSTALLER${NC}";       nap 0.05
  dbx_center "$BLUE" "${WHITE}DNSTT + EDNS Proxy (C) + MTU ${MTU}${NC}";   nap 0.05
  dbx_center "$BLUE" "${YELLOW}Ubuntu 20.04-26.04  |  Debian 10-13${NC}";  nap 0.05
  dbx_bot "$BLUE"
  echo
}

cleanup() { show_cursor; if [[ -n "$TMPD" && -d "$TMPD" ]]; then rm -rf "$TMPD"; fi; return 0; }
on_int()  { show_cursor; printf '\n'; bad "Interrupted"; kill $(jobs -p) 2>/dev/null; exit 130; }

# ----------------------------------------------------------------- SYSTEM HELPERS
OS_NAME=""; OS_ID=""; OS_VER=""

detect_os() {
  [[ -r /etc/os-release ]] || die "Cannot detect the operating system (/etc/os-release missing)."
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-unknown}"; OS_VER="${VERSION_ID:-}"; OS_NAME="${PRETTY_NAME:-$OS_ID}"
  case " ${ID:-} ${ID_LIKE:-} " in
    *" ubuntu "*|*" debian "*) ;;
    *) die "Unsupported OS: $OS_NAME. This installer supports Ubuntu and Debian (apt based)." ;;
  esac
  command -v apt-get >/dev/null 2>&1 || die "apt-get not found."
  [[ -d /run/systemd/system ]] || die "systemd is required (not running here)."
  local major="${OS_VER%%.*}"
  if [[ "$major" =~ ^[0-9]+$ ]]; then
    if [[ "$OS_ID" == "ubuntu" && "$major" -lt 20 ]]; then warn "Ubuntu $OS_VER is old; continuing anyway."; fi
    if [[ "$OS_ID" == "debian" && "$major" -lt 10 ]]; then warn "Debian $OS_VER is old; continuing anyway."; fi
  fi
}

apt_update()   { DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 update -y; }
apt_install()  { DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 install -y --no-install-recommends "$@"; }
apt_optional() { apt_install bind9-dnsutils || apt_install dnsutils; }

ssh_unit() { if systemctl list-unit-files 2>/dev/null | grep -q '^ssh\.service'; then echo ssh; else echo sshd; fi; }
udp_listening() { ss -lunH "sport = :$1" 2>/dev/null | grep -q .; }
svc_active()    { systemctl is-active --quiet "$1"; }

get_public_ip() {
  curl -fsS -m 5 https://api.ipify.org 2>/dev/null \
  || curl -fsS -m 5 https://ifconfig.me 2>/dev/null \
  || hostname -I 2>/dev/null | awk '{print $1}'
}
detect_ip_to_file() { get_public_ip > "$TMPD/ip"; }

valid_domain() { [[ "$1" =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$ ]]; }

ask_domain() {
  while ! valid_domain "$NS_DOMAIN"; do
    if [[ -n "$NS_DOMAIN" ]]; then bad "'$NS_DOMAIN' is not a valid domain name"; fi
    if [[ ! -r /dev/tty ]]; then
      die "No terminal available. Run:  NS_DOMAIN=t.example.com bash $0"
    fi
    echo "${WHITE}${BOLD}Enter your tunnel nameserver domain${NC}"
    bx_top "$CYAN"
    bx_row "$CYAN" "${YELLOW}Example:${NC} t.yourdomain.com"
    bx_row "$CYAN" "${DIM}(the NS record of this name points to this server)${NC}"
    bx_bot "$CYAN"
    printf '%s%sNameserver: %s' "$WHITE" "$BOLD" "$NC"
    read -r NS_DOMAIN </dev/tty || die "Input cancelled."
    NS_DOMAIN="${NS_DOMAIN//[[:space:]]/}"
  done
}

# ----------------------------------------------------------------- DOWNLOAD / VERIFY
dl() {   # url dest
  local url="$1" dest="$2"
  if [[ -n "$GITHUB_TOKEN" ]]; then
    curl -fsSL --retry 3 --connect-timeout 10 -H "Authorization: token $GITHUB_TOKEN" "$url" -o "$dest"
  else
    curl -fsSL --retry 3 --connect-timeout 10 "$url" -o "$dest" || wget -q -O "$dest" "$url"
  fi
}

fetch_asset() {   # name  -> $FASTDNS_DIR/name (atomic, only replaced on success)
  local name="$1" dest="$FASTDNS_DIR/$1"
  rm -f "$dest.new"
  if [[ -s "$SCRIPT_DIR/$name" && "$SCRIPT_DIR" != "$FASTDNS_DIR" ]]; then
    cp -f "$SCRIPT_DIR/$name" "$dest.new"
  else
    dl "$GITHUB_BASE/$name" "$dest.new" || { rm -f "$dest.new"; return 1; }
  fi
  [[ -s "$dest.new" ]] || { rm -f "$dest.new"; return 1; }
  mv -f "$dest.new" "$dest"
}

elf_ok() {   # file -> is an ELF binary that matches this CPU
  local f="$1" m want
  [[ "$(head -c4 "$f" 2>/dev/null | tail -c3)" == "ELF" ]] || return 1
  m="$(od -An -tx1 -j18 -N1 "$f" 2>/dev/null | tr -d ' \n')"
  case "$(uname -m)" in
    x86_64|amd64)  want="3e" ;;
    aarch64|arm64) want="b7" ;;
    armv7l|armv6l) want="28" ;;
    i?86)          want="03" ;;
    *)             return 0 ;;
  esac
  [[ "$m" == "$want" ]]
}

fetch_binary() {
  fetch_asset dnstt-server || return 1
  if ! elf_ok "$FASTDNS_DIR/dnstt-server"; then
    echo "dnstt-server is not a valid binary for $(uname -m)"; rm -f "$FASTDNS_DIR/dnstt-server"; return 1
  fi
  chmod 755 "$FASTDNS_DIR/dnstt-server"
}

build_dnstt_from_source() {
  apt_install golang-go git ca-certificates
  GOBIN="$FASTDNS_DIR" GOPATH="$TMPD/gopath" HOME="$TMPD" \
    go install www.bamsoftware.com/git/dnstt.git/dnstt-server@latest
  chmod 755 "$FASTDNS_DIR/dnstt-server"
}

gen_keys() {
  rm -f "$FASTDNS_DIR/server.key" "$FASTDNS_DIR/server.pub"
  "$FASTDNS_DIR/dnstt-server" -gen-key -privkey-file "$FASTDNS_DIR/server.key" -pubkey-file "$FASTDNS_DIR/server.pub"
}

fetch_keys() { fetch_asset server.key && fetch_asset server.pub; }

# ----------------------------------------------------------------- EDNS PROXY (C SOURCE)
write_proxy_source() {
cat > "$1" <<'CEOF'
/*
 * edns-proxy.c - UDP DNS proxy: EDNS0 size rewriting + per-domain routing.
 *
 *   resolver -> :53 [edns-proxy] -> -u host:port            (default / main domain)
 *                               \-> -r domain=host:port ... (extra tunnel domains)
 *
 * Queries : the OPT record's advertised payload size is raised to -s (1800),
 *           so dnstt-server may send larger responses.
 *           The query name picks the backend: names ending in a -r domain go
 *           to that backend, everything else goes to the -u backend.
 * Replies : the OPT payload size is restored to what the resolver sent.
 *
 * Multi-process (SO_REUSEPORT), epoll based, transaction-ID remapping.
 */
#define _GNU_SOURCE
#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define BUF_SZ    4096
#define TABLE_SZ  65536
#define ENTRY_TTL 10
#define BATCH     256
#define MAXR      16

struct entry {
    struct sockaddr_storage addr;
    socklen_t alen;
    uint16_t orig_id;
    uint16_t orig_size;
    uint8_t  has_opt;
    uint8_t  used;
    time_t   ts;
};

struct route {
    char suffix[256];          /* lower-case domain, no trailing dot (route 0: unused) */
    int  slen;
    struct sockaddr_in up;
};

static struct route routes[MAXR];   /* routes[0] = default backend */
static int nroutes = 0;

static volatile sig_atomic_t g_stop = 0;
static void on_term(int s) { (void)s; g_stop = 1; }

static inline uint16_t rd16(const uint8_t *p) { return (uint16_t)((p[0] << 8) | p[1]); }
static inline void wr16(uint8_t *p, uint16_t v) { p[0] = v >> 8; p[1] = v & 0xff; }

/* Skip a (possibly compressed) DNS name. Returns offset after it, or -1. */
static int skip_name(const uint8_t *p, int len, int off)
{
    int steps = 0;
    while (off < len) {
        uint8_t c = p[off];
        if (c == 0) return off + 1;
        if ((c & 0xC0) == 0xC0) return (off + 2 <= len) ? off + 2 : -1;
        if (c & 0xC0) return -1;
        off += 1 + c;
        if (++steps > 128) return -1;
    }
    return -1;
}

/* Returns the offset of the OPT record's CLASS field (= UDP payload size), or -1. */
static int find_opt(const uint8_t *p, int len)
{
    if (len < 12) return -1;
    int qd = rd16(p + 4), an = rd16(p + 6), ns = rd16(p + 8), ar = rd16(p + 10);
    int off = 12;

    for (int i = 0; i < qd; i++) {
        off = skip_name(p, len, off);
        if (off < 0 || off + 4 > len) return -1;
        off += 4;
    }
    int total = an + ns + ar;
    for (int i = 0; i < total; i++) {
        int name_off = off;
        off = skip_name(p, len, off);
        if (off < 0 || off + 10 > len) return -1;
        uint16_t type  = rd16(p + off);
        uint16_t rdlen = rd16(p + off + 8);
        if (i >= an + ns && type == 41 && p[name_off] == 0)
            return off + 2;
        off += 10;
        if (off + rdlen > len) return -1;
        off += rdlen;
    }
    return -1;
}

/* First question name as a lower-case dotted string. Returns length or -1. */
static int get_qname(const uint8_t *p, int len, char *out, int outsz)
{
    int off = 12, o = 0;
    if (len < 13 || rd16(p + 4) < 1) return -1;
    while (off < len) {
        uint8_t c = p[off++];
        if (c == 0) { out[o] = 0; return o; }
        if (c & 0xC0) return -1;
        if (off + c > len || o + c + 2 > outsz) return -1;
        if (o) out[o++] = '.';
        for (int i = 0; i < c; i++) {
            uint8_t ch = p[off++];
            out[o++] = (ch >= 'A' && ch <= 'Z') ? (char)(ch + 32) : (char)ch;
        }
    }
    return -1;
}

static int suffix_match(const char *name, int nlen, const char *suf, int slen)
{
    if (slen <= 0 || nlen < slen) return 0;
    if (memcmp(name + nlen - slen, suf, (size_t)slen) != 0) return 0;
    return nlen == slen || name[nlen - slen - 1] == '.';
}

static int make_listener(int port)
{
    int one = 1, zero = 0, bs = 8 << 20;
    int fd = socket(AF_INET6, SOCK_DGRAM | SOCK_NONBLOCK, 0);
    if (fd >= 0) {
        struct sockaddr_in6 a;
        memset(&a, 0, sizeof a);
        a.sin6_family = AF_INET6;
        a.sin6_addr = in6addr_any;
        a.sin6_port = htons(port);
        setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &zero, sizeof zero);
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
        setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &one, sizeof one);
        setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &bs, sizeof bs);
        setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &bs, sizeof bs);
        if (bind(fd, (struct sockaddr *)&a, sizeof a) == 0) return fd;
        close(fd);
    }
    fd = socket(AF_INET, SOCK_DGRAM | SOCK_NONBLOCK, 0);
    if (fd < 0) return -1;
    struct sockaddr_in a4;
    memset(&a4, 0, sizeof a4);
    a4.sin_family = AF_INET;
    a4.sin_addr.s_addr = htonl(INADDR_ANY);
    a4.sin_port = htons(port);
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &one, sizeof one);
    setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &bs, sizeof bs);
    setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &bs, sizeof bs);
    if (bind(fd, (struct sockaddr *)&a4, sizeof a4) < 0) { close(fd); return -1; }
    return fd;
}

static void worker(int port, int edns_size)
{
    signal(SIGTERM, SIG_DFL);
    signal(SIGINT, SIG_DFL);

    int lfd = make_listener(port);
    if (lfd < 0) { perror("listen"); _exit(1); }

    int ufd[MAXR];
    int bs = 8 << 20;
    for (int r = 0; r < nroutes; r++) {
        ufd[r] = socket(AF_INET, SOCK_DGRAM | SOCK_NONBLOCK, 0);
        if (ufd[r] < 0 || connect(ufd[r], (const struct sockaddr *)&routes[r].up, sizeof routes[r].up) < 0) {
            perror("upstream"); _exit(1);
        }
        setsockopt(ufd[r], SOL_SOCKET, SO_RCVBUF, &bs, sizeof bs);
        setsockopt(ufd[r], SOL_SOCKET, SO_SNDBUF, &bs, sizeof bs);
    }

    struct entry *table = calloc(TABLE_SZ, sizeof *table);
    if (!table) _exit(1);
    uint16_t next = (uint16_t)(getpid() * 40503u);

    int ep = epoll_create1(0);
    struct epoll_event ev;
    memset(&ev, 0, sizeof ev);
    ev.events = EPOLLIN;
    ev.data.u32 = 0;                 epoll_ctl(ep, EPOLL_CTL_ADD, lfd, &ev);
    for (int r = 0; r < nroutes; r++) {
        ev.data.u32 = (uint32_t)(r + 1);
        epoll_ctl(ep, EPOLL_CTL_ADD, ufd[r], &ev);
    }

    uint8_t buf[BUF_SZ];
    struct epoll_event evs[MAXR + 1];

    for (;;) {
        int k = epoll_wait(ep, evs, MAXR + 1, 1000);
        if (k < 0) { if (errno == EINTR) continue; break; }
        time_t now = time(NULL);

        for (int i = 0; i < k; i++) {
            uint32_t id = evs[i].data.u32;
            if (id == 0) {
                /* ---- resolver -> dnstt-server (pick backend by query name) ---- */
                for (int j = 0; j < BATCH; j++) {
                    struct sockaddr_storage ss;
                    socklen_t sl = sizeof ss;
                    ssize_t n = recvfrom(lfd, buf, BUF_SZ, 0, (struct sockaddr *)&ss, &sl);
                    if (n < 0) break;
                    if (n < 12 || (buf[2] & 0x80)) continue;   /* not a query */

                    int r = 0;
                    if (nroutes > 1) {
                        char qn[256];
                        int ql = get_qname(buf, (int)n, qn, sizeof qn);
                        if (ql > 0) {
                            for (int q = 1; q < nroutes; q++) {
                                if (suffix_match(qn, ql, routes[q].suffix, routes[q].slen)) { r = q; break; }
                            }
                        }
                    }

                    uint16_t slot = next++;
                    struct entry *e = &table[slot];
                    e->addr = ss; e->alen = sl;
                    e->orig_id = rd16(buf);
                    e->ts = now; e->used = 1;

                    int o = find_opt(buf, (int)n);
                    if (o >= 0) {
                        e->has_opt = 1;
                        e->orig_size = rd16(buf + o);
                        if (e->orig_size < edns_size) wr16(buf + o, (uint16_t)edns_size);
                    } else {
                        e->has_opt = 0;
                    }
                    wr16(buf, slot);
                    send(ufd[r], buf, (size_t)n, 0);
                }
            } else {
                /* ---- dnstt-server -> resolver ---- */
                int r = (int)id - 1;
                if (r < 0 || r >= nroutes) continue;
                for (int j = 0; j < BATCH; j++) {
                    ssize_t n = recv(ufd[r], buf, BUF_SZ, 0);
                    if (n < 0) break;
                    if (n < 12 || !(buf[2] & 0x80)) continue;   /* not a response */

                    struct entry *e = &table[rd16(buf)];
                    if (!e->used || now - e->ts > ENTRY_TTL) continue;

                    wr16(buf, e->orig_id);
                    if (e->has_opt) {
                        int o = find_opt(buf, (int)n);
                        if (o >= 0) wr16(buf + o, e->orig_size);
                    }
                    sendto(lfd, buf, (size_t)n, 0, (struct sockaddr *)&e->addr, e->alen);
                    e->used = 0;
                }
            }
        }
    }
    _exit(0);
}

static int parse_up(const char *s, struct sockaddr_in *up)
{
    char host[64];
    const char *colon = strrchr(s, ':');
    if (!colon || (size_t)(colon - s) >= sizeof host) return -1;
    memcpy(host, s, (size_t)(colon - s));
    host[colon - s] = 0;
    memset(up, 0, sizeof *up);
    up->sin_family = AF_INET;
    up->sin_port = htons((uint16_t)atoi(colon + 1));
    return inet_pton(AF_INET, host, &up->sin_addr) == 1 ? 0 : -1;
}

int main(int argc, char **argv)
{
    int port = 53, size = 1800, workers = 2, opt, nr = 0;
    const char *upstr = "127.0.0.1:5300";
    const char *rarg[MAXR];

    while ((opt = getopt(argc, argv, "l:u:s:w:r:")) != -1) {
        switch (opt) {
        case 'l': port = atoi(optarg); break;
        case 'u': upstr = optarg; break;
        case 's': size = atoi(optarg); break;
        case 'w': workers = atoi(optarg); break;
        case 'r':
            if (nr >= MAXR - 1) { fprintf(stderr, "too many -r routes\n"); return 2; }
            rarg[nr++] = optarg;
            break;
        default:
            fprintf(stderr, "usage: %s [-l port] [-u host:port] [-s edns_size] [-w workers] [-r domain=host:port]...\n", argv[0]);
            return 2;
        }
    }
    if (size < 512) size = 512;
    if (size > 4096) size = 4096;
    if (workers < 1) workers = 1;
    if (workers > 16) workers = 16;

    if (parse_up(upstr, &routes[0].up) < 0) { fprintf(stderr, "bad -u\n"); return 2; }
    nroutes = 1;
    for (int i = 0; i < nr; i++) {
        const char *eq = strchr(rarg[i], '=');
        if (!eq || eq == rarg[i]) { fprintf(stderr, "bad -r (want domain=host:port)\n"); return 2; }
        size_t dl = (size_t)(eq - rarg[i]);
        struct route *rt = &routes[nroutes];
        if (dl >= sizeof rt->suffix) { fprintf(stderr, "domain too long\n"); return 2; }
        for (size_t j = 0; j < dl; j++) {
            char ch = rarg[i][j];
            rt->suffix[j] = (ch >= 'A' && ch <= 'Z') ? (char)(ch + 32) : ch;
        }
        rt->suffix[dl] = 0;
        if (dl && rt->suffix[dl - 1] == '.') rt->suffix[--dl] = 0;
        rt->slen = (int)dl;
        if (parse_up(eq + 1, &rt->up) < 0) { fprintf(stderr, "bad -r backend\n"); return 2; }
        nroutes++;
    }

    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = on_term;           /* no SA_RESTART: wait() must be interruptible */
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);

    fprintf(stderr, "edns-proxy: :%d -> %s (+%d domain route(s)), edns=%d, workers=%d\n",
            port, upstr, nroutes - 1, size, workers);

    for (int i = 0; i < workers; i++) {
        pid_t p = fork();
        if (p == 0) worker(port, size);
        if (p < 0) { perror("fork"); return 1; }
    }
    while (!g_stop) {
        pid_t p = wait(NULL);
        if (g_stop) break;
        if (p > 0) {                   /* respawn a dead worker */
            sleep(1);
            if (fork() == 0) worker(port, size);
        } else if (errno != EINTR) {
            break;
        }
    }
    return 0;
}
CEOF
}

build_proxy() {
  write_proxy_source "$TMPD/edns-proxy.c"
  gcc -O2 -Wall -o "$PROXY_BIN.new" "$TMPD/edns-proxy.c" \
    && mv -f "$PROXY_BIN.new" "$PROXY_BIN" \
    && chmod 755 "$PROXY_BIN"
}

# ----------------------------------------------------------------- TUNING
write_sysctl() {
  modprobe tcp_bbr 2>/dev/null || true
  local cc=""
  if grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
    cc="net.ipv4.tcp_congestion_control = bbr"
  fi
  cat > /etc/sysctl.d/99-fastdns.conf <<EOF
# --- FastDns performance tuning ---
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.core.netdev_max_backlog = 50000
net.core.somaxconn = 8192
net.core.default_qdisc = fq
net.ipv4.udp_mem = 262144 524288 1048576
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.tcp_rmem = 4096 262144 33554432
net.ipv4.tcp_wmem = 4096 262144 33554432
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fastopen = 3
# MTU ${MTU} means DNS replies fragment at IP level: give reassembly more room
net.ipv4.ipfrag_high_thresh = 8388608
net.ipv4.ipfrag_low_thresh = 6291456
net.ipv4.ipfrag_time = 15
${cc}
EOF
  sysctl -q -p /etc/sysctl.d/99-fastdns.conf || true   # containers may reject some keys
  return 0
}

tune_ssh() {
  # Safe drop-in only: does NOT touch your root-login / password settings.
  [[ -d /etc/ssh/sshd_config.d ]] || { echo "no sshd_config.d, skipping"; return 1; }
  grep -Eqi '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/' /etc/ssh/sshd_config \
    || { echo "sshd_config has no Include line, skipping"; return 1; }
  cat > /etc/ssh/sshd_config.d/10-fastdns.conf <<'EOF'
# FastDns: keep tunnels alive and allow many sessions
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 3
AllowTcpForwarding yes
MaxSessions 100
MaxStartups 100:30:200
UseDNS no
EOF
  mkdir -p /run/sshd
  if sshd -t 2>/dev/null; then
    systemctl reload "$(ssh_unit)" 2>/dev/null || true
  else
    rm -f /etc/ssh/sshd_config.d/10-fastdns.conf
    echo "sshd config test failed; drop-in removed"
    return 1
  fi
}

# ----------------------------------------------------------------- SERVICES
write_units() {
  local mtu_opt=""
  if "$FASTDNS_DIR/dnstt-server" -h 2>&1 | grep -q -- '-mtu'; then
    mtu_opt="-mtu ${MTU}"
  else
    echo "dnstt-server has no -mtu flag; relying on the EDNS proxy only"
  fi

  cat > /etc/systemd/system/server-sldns.service <<EOF
[Unit]
Description=FastDns Server (dnstt)
After=network-online.target $(ssh_unit).service
Wants=network-online.target

[Service]
Type=simple
User=${SVC_USER}
Group=${SVC_USER}
WorkingDirectory=${FASTDNS_DIR}
ExecStart=${FASTDNS_DIR}/dnstt-server -udp ${FASTDNS_LISTEN}:${FASTDNS_PORT} ${mtu_opt} -privkey-file ${FASTDNS_DIR}/server.key ${NS_DOMAIN} 127.0.0.1:${SSHD_PORT}
Restart=always
RestartSec=3
LimitNOFILE=1048576
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

  cat > /etc/systemd/system/edns-proxy.service <<EOF
[Unit]
Description=EDNS Proxy for FastDns (C)
After=server-sldns.service
Wants=server-sldns.service

[Service]
Type=simple
User=${SVC_USER}
Group=${SVC_USER}
ExecStart=${PROXY_BIN} -l 53 -u 127.0.0.1:${FASTDNS_PORT} -s ${EDNS_SIZE} -w ${WORKERS}$(proxy_route_args)
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
Restart=always
RestartSec=3
LimitNOFILE=1048576
Nice=-5
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
}

# ----------------------------------------------------------------- NETWORK
free_port_53() {
  if svc_active systemd-resolved; then
    mkdir -p /etc/systemd/resolved.conf.d
    printf '[Resolve]\nDNSStubListener=no\n' > /etc/systemd/resolved.conf.d/10-fastdns.conf
    if [[ -L /etc/resolv.conf ]] && readlink -f /etc/resolv.conf | grep -q 'stub-resolv.conf'; then
      ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    fi
    systemctl restart systemd-resolved
    sleep 1
  fi
  if udp_listening 53; then
    local owner
    owner="$(ss -lunpH 'sport = :53' | grep -o 'users:(("[^"]*"' | head -1 | cut -d'"' -f2)"
    echo "UDP port 53 is already used by: ${owner:-unknown}"
    echo "Stop it first, e.g.:  systemctl disable --now ${owner:-<service>}"
    return 1
  fi
}

open_firewall() {
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q 'Status: active'; then
    ufw allow 53/udp
  fi
  if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port=53/udp && firewall-cmd --reload
  fi
  if command -v iptables >/dev/null 2>&1; then
    iptables -C INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || iptables -I INPUT -p udp --dport 53 -j ACCEPT || true
  fi
  if command -v ip6tables >/dev/null 2>&1; then
    ip6tables -C INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null || ip6tables -I INPUT -p udp --dport 53 -j ACCEPT || true
  fi
  if command -v netfilter-persistent >/dev/null 2>&1; then netfilter-persistent save || true; fi
  return 0
}

dns_roundtrip()  { dig +time=2 +tries=1 @127.0.0.1 "probe.${NS_DOMAIN}" TXT 2>/dev/null | grep -q 'status:'; }
spin_wait_dns()  { local i; for i in 1 2 3 4 5; do dns_roundtrip && return 0; sleep 1; done; return 1; }

# ----------------------------------------------------------------- RETUNE (change MTU / EDNS without reinstalling)
UNIT_DIR="${UNIT_DIR:-/etc/systemd/system}"

rewrite_units() {   # mtu edns
  local mtu="$1" edns="$2"
  local f
  for f in "$UNIT_DIR"/server-sldns.service "$UNIT_DIR"/server-sldns-*.service; do
    [[ -f "$f" ]] && sed -i -E "s/ -mtu [0-9]+/ -mtu ${mtu}/" "$f"
  done
  sed -i -E "s/ -s [0-9]+/ -s ${edns}/" "$UNIT_DIR/edns-proxy.service"
}

do_retune() {   # mtu [edns]
  local mtu="${1:-}" edns="${2:-${1:-}}"
  (( EUID == 0 )) || die "Run as root."
  [[ "$mtu" =~ ^[0-9]+$ && "$edns" =~ ^[0-9]+$ ]] || die "Usage: bash moded.sh --retune <MTU> [EDNS]   (e.g. --retune 1232)"
  (( mtu >= 512 && mtu <= 4096 && edns >= 512 && edns <= 4096 )) || die "MTU/EDNS must be between 512 and 4096"
  [[ -f "$UNIT_DIR/server-sldns.service" && -f "$UNIT_DIR/edns-proxy.service" ]] || die "FastDns is not installed yet."
  grep -q -- ' -mtu ' "$UNIT_DIR/server-sldns.service" || warn "This dnstt-server build runs without -mtu; only EDNS will change."
  rewrite_units "$mtu" "$edns"
  systemctl daemon-reload
  # shellcheck disable=SC2046
  systemctl restart server-sldns $(extra_names) edns-proxy
  sleep 2
  if svc_active server-sldns && svc_active edns-proxy; then
    ok "Retuned: MTU ${mtu}, EDNS ${edns}. Both services are running."
    if (( mtu > 1452 )); then warn "Above 1452 bytes replies fragment; if speed drops, try: bash moded.sh --retune 1232"; fi
  else
    die "A service failed after retuning: journalctl -u server-sldns -u edns-proxy -n 20"
  fi
  exit 0
}

# ----------------------------------------------------------------- EXTRA TUNNELS (more domains = more parallel tunnels)
TUNNELS_FILE_NAME="tunnels.conf"
tunnels_file()  { printf '%s/%s' "$FASTDNS_DIR" "$TUNNELS_FILE_NAME"; }
extra_units()   { ls "$UNIT_DIR"/server-sldns-*.service 2>/dev/null; }
extra_names()   { local f; for f in $(extra_units); do basename "$f" .service; done; }
start_extras()  { local n; for n in $(extra_names); do systemctl start "$n" 2>/dev/null; done; return 0; }
stop_extras()   { local n; for n in $(extra_names); do systemctl stop "$n" 2>/dev/null; done; return 0; }

proxy_route_args() {   # prints " -r domain=127.0.0.1:port ..." from tunnels.conf
  local d p out="" tf; tf="$(tunnels_file)"
  [[ -s "$tf" ]] || return 0
  while read -r d p; do
    if [[ -n "$d" && "$p" =~ ^[0-9]+$ ]]; then out+=" -r ${d}=127.0.0.1:${p}"; fi
  done < "$tf"
  printf '%s' "$out"
}

refresh_proxy_unit() {   # rebuild the proxy ExecStart line from tunnels.conf
  local f="$UNIT_DIR/edns-proxy.service" cur edns workers up line
  cur="$(grep '^ExecStart=' "$f")"
  edns="$(sed -nE 's/.* -s ([0-9]+).*/\1/p' <<<"$cur")"
  workers="$(sed -nE 's/.* -w ([0-9]+).*/\1/p' <<<"$cur")"
  up="$(sed -nE 's/.* -u ([^ ]+).*/\1/p' <<<"$cur")"
  line="ExecStart=${PROXY_BIN} -l 53 -u ${up} -s ${edns} -w ${workers}$(proxy_route_args)"
  sed -i "s#^ExecStart=.*#${line}#" "$f"
}

main_domain() { sed -nE 's/^ExecStart=.*-privkey-file [^ ]+ ([^ ]+) [^ ]+$/\1/p' "$UNIT_DIR/server-sldns.service"; }

next_tunnel_port() {
  local p=$(( FASTDNS_PORT + 1 )) tf; tf="$(tunnels_file)"
  while awk -v p="$p" '$2==p{f=1} END{exit !f}' "$tf" 2>/dev/null || udp_listening "$p"; do p=$(( p + 1 )); done
  echo "$p"
}

do_add_tunnel() {   # domain
  local dom="${1:-}" port unit tf; tf="$(tunnels_file)"
  (( EUID == 0 )) || die "Run as root."
  dom="${dom,,}"
  valid_domain "$dom" || die "Usage: bash moded.sh --add-tunnel t2.example.com"
  [[ -f "$UNIT_DIR/server-sldns.service" ]] || die "Install FastDns first (run moded.sh without options)."
  [[ "$dom" != "$(main_domain)" ]] || die "$dom is already the main tunnel."
  if [[ -f "$tf" ]] && awk -v d="$dom" '$1==d{f=1} END{exit !f}' "$tf"; then die "$dom was already added."; fi
  mkdir -p "$FASTDNS_DIR"; mkdir -p "$(dirname "$LOG_FILE")"; touch "$LOG_FILE"
  TMPD="$(mktemp -d)"; trap cleanup EXIT

  port="$(next_tunnel_port)"
  unit="$UNIT_DIR/server-sldns-${port}.service"
  sed -E "s#-udp ([0-9.]+):[0-9]+#-udp \1:${port}#; s#(-privkey-file [^ ]+) [^ ]+ ([^ ]+)\$#\1 ${dom} \2#; s#^Description=.*#Description=FastDns Server (dnstt) ${dom}#" \
    "$UNIT_DIR/server-sldns.service" > "$unit"
  echo "${dom} ${port}" >> "$tf"

  info "Rebuilding the EDNS proxy with domain routing..."
  build_proxy >>"$LOG_FILE" 2>&1 || die "Proxy compile failed (see $LOG_FILE)"
  refresh_proxy_unit
  systemctl daemon-reload
  systemctl enable --now "server-sldns-${port}" >/dev/null 2>&1
  systemctl restart edns-proxy
  sleep 2
  if svc_active "server-sldns-${port}" && svc_active edns-proxy; then
    ok "Tunnel added: ${dom}  (backend 127.0.0.1:${port})"
    echo
    info "Now add this DNS record at your DNS provider (same ns host as before):"
    echo "    ${YELLOW}NS${NC}  ${dom}  ->  ns1.yourdomain.com"
    info "Clients use the same server.pub with domain ${dom}."
    info "Use a different resolver for each tunnel, so they do not share one rate limit."
  else
    die "Tunnel failed to start: journalctl -u server-sldns-${port} -n 20"
  fi
  exit 0
}

do_remove_tunnel() {   # domain
  local dom="${1:-}" tf port; tf="$(tunnels_file)"
  (( EUID == 0 )) || die "Run as root."
  dom="${dom,,}"
  [[ -s "$tf" ]] || die "No extra tunnels are configured."
  port="$(awk -v d="$dom" '$1==d{print $2}' "$tf")"
  [[ -n "$port" ]] || die "$dom is not an extra tunnel. See: bash moded.sh --tunnels"
  systemctl disable --now "server-sldns-${port}" >/dev/null 2>&1
  rm -f "$UNIT_DIR/server-sldns-${port}.service"
  awk -v d="$dom" '$1!=d' "$tf" > "$tf.new" && mv -f "$tf.new" "$tf"
  refresh_proxy_unit
  systemctl daemon-reload
  systemctl restart edns-proxy
  ok "Tunnel removed: ${dom}"
  exit 0
}

do_list_tunnels() {
  local tf d p st; tf="$(tunnels_file)"
  [[ -f "$UNIT_DIR/server-sldns.service" ]] || die "FastDns is not installed."
  st="stopped"; svc_active server-sldns && st="running"
  printf '  %s%-34s%s %-6s %s\n' "$WHITE" "DOMAIN" "$NC" "PORT" "STATUS"
  printf '  %-34s %-6s %s\n' "$(main_domain) (main)" "$FASTDNS_PORT" "$st"
  if [[ -s "$tf" ]]; then
    while read -r d p; do
      st="stopped"; svc_active "server-sldns-${p}" && st="running"
      printf '  %-34s %-6s %s\n' "$d" "$p" "$st"
    done < "$tf"
  fi
  exit 0
}

# ----------------------------------------------------------------- UNINSTALL
do_uninstall() {
  (( EUID == 0 )) || die "Run as root."
  banner
  echo "${WHITE}${BOLD}Removing FastDns...${NC}"
  systemctl disable --now edns-proxy server-sldns 2>/dev/null
  local n
  for n in $(extra_names); do systemctl disable --now "$n" 2>/dev/null; rm -f "$UNIT_DIR/$n.service"; done
  if [[ -s "$FASTDNS_DIR/server.key" ]]; then
    mkdir -p /root/fastdns-keys-backup && cp -f "$FASTDNS_DIR"/server.key "$FASTDNS_DIR"/server.pub /root/fastdns-keys-backup/ 2>/dev/null
    ok "Keys backed up to /root/fastdns-keys-backup"
  fi
  rm -f /etc/systemd/system/server-sldns.service /etc/systemd/system/edns-proxy.service "$PROXY_BIN" \
        /etc/sysctl.d/99-fastdns.conf /etc/ssh/sshd_config.d/10-fastdns.conf
  rm -rf "$FASTDNS_DIR"
  if [[ -f /etc/systemd/resolved.conf.d/10-fastdns.conf ]]; then
    rm -f /etc/systemd/resolved.conf.d/10-fastdns.conf
    if [[ "$(readlink /etc/resolv.conf)" == "/run/systemd/resolve/resolv.conf" ]]; then
      ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    fi
    systemctl restart systemd-resolved 2>/dev/null
  fi
  systemctl daemon-reload; sysctl --system >/dev/null 2>&1
  systemctl reload "$(ssh_unit)" 2>/dev/null
  ok "FastDns removed"
  exit 0
}

# ----------------------------------------------------------------- SUMMARY + MENU
show_summary() {
  local ip="$1" elapsed=$(( SECONDS - T0 ))
  echo
  dbx_top "$GREEN"
  dbx_center "$GREEN" "${WHITE}${BOLD}INSTALLATION COMPLETE${NC}"
  dbx_center "$GREEN" "${WHITE}Finished in ${elapsed}s  |  FastDns + EDNS Proxy${NC}"
  dbx_bot "$GREEN"

  echo; bx_top "$CYAN"
  bx_row "$CYAN" "${WHITE}${BOLD}SERVER INFORMATION${NC}"; bx_mid "$CYAN"
  bx_row "$CYAN" "${YELLOW}●${NC} Server IP    : ${WHITE}${ip}${NC}"
  bx_row "$CYAN" "${YELLOW}●${NC} Nameserver   : ${WHITE}${NS_DOMAIN}${NC}"
  bx_row "$CYAN" "${YELLOW}●${NC} SSH port     : ${WHITE}${SSHD_PORT}${NC}"
  bx_row "$CYAN" "${YELLOW}●${NC} EDNS proxy   : ${WHITE}UDP 53  (EDNS ${EDNS_SIZE})${NC}"
  bx_row "$CYAN" "${YELLOW}●${NC} FastDns      : ${WHITE}${FASTDNS_LISTEN}:${FASTDNS_PORT}  (MTU ${MTU})${NC}"
  bx_row "$CYAN" "${YELLOW}●${NC} OS           : ${WHITE}${OS_NAME}${NC}"
  bx_bot "$CYAN"

  echo; bx_top "$CYAN"
  bx_row "$CYAN" "${WHITE}${BOLD}DNS RECORDS TO CREATE${NC}"; bx_mid "$CYAN"
  bx_row "$CYAN" "${YELLOW}A  ${NC} ns1.yourdomain.com  ->  ${WHITE}${ip}${NC}"
  bx_row "$CYAN" "${YELLOW}NS ${NC} ${NS_DOMAIN}"
  bx_row "$CYAN" "      ->  ns1.yourdomain.com"
  bx_bot "$CYAN"

  echo; bx_top "$CYAN"
  bx_row "$CYAN" "${WHITE}${BOLD}CLIENT EXAMPLE${NC}"; bx_mid "$CYAN"
  bx_row "$CYAN" "${GREEN}./dnstt-client -udp 8.8.8.8:53 \\${NC}"
  bx_row "$CYAN" "${GREEN}  -pubkey-file server.pub \\${NC}"
  bx_row "$CYAN" "${GREEN}  ${NS_DOMAIN} 127.0.0.1:1080${NC}"
  bx_bot "$CYAN"

  echo; bx_top "$CYAN"
  bx_row "$CYAN" "${WHITE}${BOLD}MANAGE${NC}"; bx_mid "$CYAN"
  bx_row "$CYAN" "${GREEN}systemctl restart server-sldns edns-proxy${NC}"
  bx_row "$CYAN" "${GREEN}journalctl -u server-sldns -f${NC}"
  bx_row "$CYAN" "${GREEN}ss -ulpn | grep -E ':53 |:${FASTDNS_PORT} '${NC}"
  bx_bot "$CYAN"

  if [[ -s "$FASTDNS_DIR/server.pub" ]]; then
    echo; echo "${WHITE}${BOLD}PUBLIC KEY (give this to clients):${NC}"
    echo "${GREEN}$(head -1 "$FASTDNS_DIR/server.pub")${NC}"
  fi
  echo
  echo "${DIM}Tuning raises limits for speed, but real DNS-tunnel throughput depends on${NC}"
  echo "${DIM}the resolver and network path; 20 MB/s is not guaranteed.${NC}"
  if [[ -n "$CONTACT_LINE" ]]; then echo; echo "${YELLOW}${BOLD}${CONTACT_LINE}${NC}"; fi
}

post_menu() {
  [[ -r /dev/tty ]] || return 0
  local opt
  while true; do
    echo; bx_top "$CYAN"
    bx_row "$CYAN" "${WHITE}${BOLD}POST-INSTALLATION OPTIONS${NC}"; bx_mid "$CYAN"
    bx_row "$CYAN" "${YELLOW}1.${NC} View service status"
    bx_row "$CYAN" "${YELLOW}2.${NC} Check listening ports"
    bx_row "$CYAN" "${YELLOW}3.${NC} Restart all services"
    bx_row "$CYAN" "${YELLOW}4.${NC} View installation log"
    bx_row "$CYAN" "${YELLOW}5.${NC} Test DNS functionality"
    bx_row "$CYAN" "${YELLOW}6.${NC} Show public key"
    bx_row "$CYAN" "${YELLOW}7.${NC} Exit"
    bx_bot "$CYAN"
    printf '%s%sSelect option [1-7]: %s' "$WHITE" "$BOLD" "$NC"
    read -r opt </dev/tty || break
    echo
    case "$opt" in
      1) systemctl status server-sldns edns-proxy --no-pager -l ;;
      2) echo "${WHITE}UDP:${NC}"; ss -ulpn | grep -E ':53 |:'"$FASTDNS_PORT"' '
         echo "${WHITE}TCP (ssh):${NC}"; ss -tlnp | grep -E ":${SSHD_PORT} " ;;
      3) systemctl restart server-sldns edns-proxy; sleep 2
         if svc_active server-sldns && svc_active edns-proxy; then ok "Services restarted"; else warn "A service failed to restart"; fi ;;
      4) tail -n 40 "$LOG_FILE" ;;
      5) if command -v dig >/dev/null 2>&1; then
           if dns_roundtrip; then ok "Proxy answered a DNS query"; else warn "No DNS answer from 127.0.0.1:53"; fi
         else warn "dig is not installed (apt install bind9-dnsutils)"; fi ;;
      6) cat "$FASTDNS_DIR/server.pub" ;;
      7|q|Q|"") break ;;
      *) warn "Invalid option" ;;
    esac
  done
  echo; echo "${GREEN}${BOLD}Done. $(date)${NC}"
}

# ----------------------------------------------------------------- MAIN
main() {
  case "${1:-}" in
    --uninstall) do_uninstall ;;
    --retune)    do_retune "${2:-}" "${3:-}" ;;
    --add-tunnel)    do_add_tunnel "${2:-}" ;;
    --remove-tunnel) do_remove_tunnel "${2:-}" ;;
    --tunnels)       do_list_tunnels ;;
    -h|--help)   sed -n '2,20p' "${BASH_SOURCE[0]:-$0}" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    "")          ;;
    *)           NS_DOMAIN="${NS_DOMAIN:-$1}" ;;
  esac

  if (( EUID != 0 )); then bad "Please run this script as root (sudo -i  or  su -)."; exit 1; fi
  mkdir -p "$(dirname "$LOG_FILE")"; : > "$LOG_FILE"; chmod 600 "$LOG_FILE"
  TMPD="$(mktemp -d)"
  trap cleanup EXIT
  trap on_int INT TERM
  local v
  for v in SSHD_PORT FASTDNS_PORT MTU EDNS_SIZE WORKERS; do
    [[ "${!v}" =~ ^[0-9]+$ ]] || die "$v must be a number (got '${!v}')"
  done

  hide_cursor
  banner
  detect_os
  ok "Detected ${OS_NAME} (${OS_ID} ${OS_VER:-rolling}) on $(uname -m)"
  show_cursor
  ask_domain
  hide_cursor
  spin_try "Detecting server IP address" detect_ip_to_file
  SERVER_IP="$(cat "$TMPD/ip" 2>/dev/null)"; SERVER_IP="${SERVER_IP:-unknown}"
  ok "Server IP: ${WHITE}${BOLD}${SERVER_IP}${NC}"

  # ---------------------------------------------------------------- STEP 1
  step 1 "System check & dependencies"
  spin_run "Updating package lists" apt_update || die "apt update failed"
  spin_run "Installing gcc, curl, iproute2, openssh-server" \
    apt_install gcc libc6-dev curl ca-certificates iproute2 procps psmisc openssh-server \
    || die "Package installation failed"
  spin_try "Installing DNS test tools (dig)" apt_optional
  id "$SVC_USER" >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin "$SVC_USER"
  systemctl enable --now "$(ssh_unit)" >/dev/null 2>&1
  ok "Service account '${SVC_USER}' and SSH ready"
  step_end

  # ---------------------------------------------------------------- STEP 2
  step 2 "Fetching FastDns binary & keys"
  systemctl stop edns-proxy server-sldns >/dev/null 2>&1
  stop_extras
  mkdir -p "$FASTDNS_DIR"
  info "Source: ${GITHUB_BASE}"
  if ! spin_try "Downloading dnstt-server" fetch_binary; then
    if [[ -x "$FASTDNS_DIR/dnstt-server" ]]; then
      warn "Download failed, keeping the existing binary"
    else
      warn "Repo download failed (private repo? set GITHUB_TOKEN). Trying a source build..."
      spin_run "Building dnstt-server from source (Go)" build_dnstt_from_source \
        || die "No dnstt-server binary available."
    fi
  fi
  timeout 5 "$FASTDNS_DIR/dnstt-server" -h >/dev/null 2>&1; rc=$?
  if (( rc == 126 || rc == 127 )); then die "dnstt-server cannot run on this machine ($(uname -m))."; fi
  if spin_try "Downloading server.key & server.pub" fetch_keys; then
    ok "Keys loaded from repo"
  elif [[ -s "$FASTDNS_DIR/server.key" && -s "$FASTDNS_DIR/server.pub" ]]; then
    warn "Repo keys unavailable, keeping the existing keypair"
  else
    spin_run "Generating a new keypair" gen_keys || die "Key generation failed"
    warn "New keys generated: give clients the new server.pub"
  fi
  chmod 600 "$FASTDNS_DIR/server.key"; chmod 644 "$FASTDNS_DIR/server.pub"
  step_end

  # ---------------------------------------------------------------- STEP 3
  step 3 "Compiling the EDNS proxy (C)"
  spin_run "Compiling edns-proxy (gcc -O2)" build_proxy || die "Compilation failed (see log)"
  ok "Installed ${PROXY_BIN}  (EDNS ${EDNS_SIZE}, ${WORKERS} worker(s))"
  step_end

  # ---------------------------------------------------------------- STEP 4
  step 4 "Performance tuning"
  spin_run "Applying kernel network tuning (BBR, buffers, frag)" write_sysctl
  spin_try "Optimising SSH for many tunnel sessions" tune_ssh
  step_end

  # ---------------------------------------------------------------- STEP 5
  step 5 "Creating system services"
  chown -R "$SVC_USER:$SVC_USER" "$FASTDNS_DIR"
  spin_run "Writing server-sldns & edns-proxy units" write_units || die "Could not write services"
  step_end

  # ---------------------------------------------------------------- STEP 6
  step 6 "Network & firewall"
  spin_run "Freeing UDP port 53" free_port_53 || die "UDP port 53 is busy (see the message above)"
  spin_run "Opening UDP 53 in the firewall" open_firewall
  step_end

  # ---------------------------------------------------------------- STEP 7
  step 7 "Starting & verifying"
  systemctl enable server-sldns edns-proxy >/dev/null 2>&1
  systemctl restart server-sldns
  spin_wait "FastDns listening on ${FASTDNS_LISTEN}:${FASTDNS_PORT}" 15 udp_listening "$FASTDNS_PORT" \
    || { journalctl -u server-sldns -n 15 --no-pager 2>/dev/null | sed 's/^/      /'; die "server-sldns failed to start"; }
  start_extras
  systemctl restart edns-proxy
  spin_wait "EDNS proxy listening on UDP 53" 15 udp_listening 53 \
    || { journalctl -u edns-proxy -n 15 --no-pager 2>/dev/null | sed 's/^/      /'; die "edns-proxy failed to start"; }
  if svc_active server-sldns && svc_active edns-proxy; then ok "Both services are active"; else warn "A service is not active"; fi
  if command -v dig >/dev/null 2>&1; then
    spin_try "DNS round-trip through the proxy" spin_wait_dns
  fi
  step_end

  show_cursor
  show_summary "$SERVER_IP"
  post_menu
}

if [[ -z "${FASTDNS_SOURCE_ONLY:-}" ]]; then
  main "$@"
fi
FF_FASTDNS_MODED_EOF
    chmod 755 "$FASTDNS_MODED_SCRIPT"
}

run_fastdns_moded() {
    write_fastdns_moded_script
    bash "$FASTDNS_MODED_SCRIPT" "$@"
}

fastdns_installed() {
    [ -f "$FASTDNS_SERVICE_FILE" ]
}

fastdns_main_domain() {
    sed -nE 's/^ExecStart=.*-privkey-file [^ ]+ ([^ ]+) [^ ]+$/\1/p' "$FASTDNS_SERVICE_FILE" 2>/dev/null
}

fastdns_extra_domains() {
    [ -s "$FASTDNS_TUNNELS_FILE" ] && awk '{print $1}' "$FASTDNS_TUNNELS_FILE"
}

fastdns_pubkey() {
    head -1 "$FASTDNS_KEYS_PUB" 2>/dev/null
}

remove_legacy_dnstt() {
    # Removes the old visibleTech dnstt.service install (replaced by FastDns Moded).
    echo -e "${C_BLUE}🛑 Removing the old DNSTT service...${C_RESET}"
    systemctl stop dnstt.service > /dev/null 2>&1
    systemctl disable dnstt.service > /dev/null 2>&1
    if [ -f "$DNSTT_CONFIG_FILE" ]; then
        source "$DNSTT_CONFIG_FILE"
        if [[ "$DNSTT_RECORDS_MANAGED" == "true" ]]; then
            echo -e "${C_BLUE}🗑️ Removing auto-generated DNS records...${C_RESET}"
            curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$TUNNEL_SUBDOMAIN/NS/" \
                 -H "Authorization: Token $DESEC_TOKEN" > /dev/null
            curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$NS_SUBDOMAIN/A/" \
                 -H "Authorization: Token $DESEC_TOKEN" > /dev/null
            if [[ "$HAS_IPV6" == "true" ]]; then
                curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$NS_SUBDOMAIN/AAAA/" \
                     -H "Authorization: Token $DESEC_TOKEN" > /dev/null
            fi
        fi
    fi
    rm -f "$DNSTT_SERVICE_FILE" "$DNSTT_BINARY" "$DNSTT_CONFIG_FILE"
    rm -rf "$DNSTT_KEYS_DIR"
    systemctl daemon-reload
    chattr -i /etc/resolv.conf &>/dev/null
    systemctl unmask systemd-resolved &>/dev/null
    systemctl enable systemd-resolved &>/dev/null
    systemctl start systemd-resolved &>/dev/null
    echo -e "${C_GREEN}✅ Old DNSTT removed.${C_RESET}"
}

show_dnstt_details() {
    if ! fastdns_installed; then
        echo -e "\n${C_YELLOW}ℹ️ FastDns (DNSTT) is not installed. Details are unavailable.${C_RESET}"
        return
    fi
    local main_dom pub mtu edns fwd extra d
    main_dom=$(fastdns_main_domain)
    pub=$(fastdns_pubkey)
    mtu=$(sed -nE 's/^ExecStart=.* -mtu ([0-9]+) .*/\1/p' "$FASTDNS_SERVICE_FILE")
    fwd=$(sed -nE 's/^ExecStart=.* ([^ ]+)$/\1/p' "$FASTDNS_SERVICE_FILE")
    edns=$(sed -nE 's/^ExecStart=.* -s ([0-9]+) .*/\1/p' "$FASTDNS_EDNS_SERVICE_FILE" 2>/dev/null)

    echo -e "\n${C_GREEN}=====================================================${C_RESET}"
    echo -e "${C_GREEN}        📡 DNSTT (FastDns Moded) Connection Details    ${C_RESET}"
    echo -e "${C_GREEN}=====================================================${C_RESET}"
    echo -e "\n${C_WHITE}Your connection details:${C_RESET}"
    echo -e "  - ${C_CYAN}Tunnel Domain:${C_RESET} ${C_YELLOW}${main_dom:-unknown}${C_RESET}"
    while read -r d; do
        [[ -n "$d" ]] && echo -e "  - ${C_CYAN}Extra Tunnel:${C_RESET}  ${C_YELLOW}$d${C_RESET}"
    done < <(fastdns_extra_domains)
    echo -e "  - ${C_CYAN}Public Key:${C_RESET}    ${C_YELLOW}${pub:-unknown}${C_RESET}"
    echo -e "  - ${C_CYAN}Forwarding To:${C_RESET} ${C_YELLOW}SSH ${fwd:-127.0.0.1:22}${C_RESET}"
    [[ -n "$mtu" ]] && echo -e "  - ${C_CYAN}MTU Value:${C_RESET}     ${C_YELLOW}$mtu${C_RESET}"
    [[ -n "$edns" ]] && echo -e "  - ${C_CYAN}EDNS Size:${C_RESET}     ${C_YELLOW}$edns${C_RESET}"
    echo -e "  - ${C_CYAN}Listening:${C_RESET}     ${C_YELLOW}UDP 53 (EDNS proxy)${C_RESET}"
    echo -e "\n${C_DIM}Client: ./dnstt-client -udp 8.8.8.8:53 -pubkey-file server.pub ${main_dom:-<domain>} 127.0.0.1:1080${C_RESET}"
    echo -e "${C_DIM}Use these details in your client configuration.${C_RESET}"
}

fastdns_manage_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- 📡 DNSTT (FastDns Moded) Management ---${C_RESET}"
        local st="${C_STATUS_I}Inactive${C_RESET}" px="${C_STATUS_I}Inactive${C_RESET}"
        systemctl is-active --quiet server-sldns && st="${C_STATUS_A}Active${C_RESET}"
        systemctl is-active --quiet edns-proxy && px="${C_STATUS_A}Active${C_RESET}"
        echo -e "\n${C_WHITE}DNSTT server:${C_RESET} ${st}"
        echo -e "${C_WHITE}EDNS proxy:${C_RESET}   ${px}"
        echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
        printf "  ${C_CHOICE}[ 1]${C_RESET} %-45s\n" "📋 Show connection details / public key"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %-45s\n" "🎚️ Retune MTU / EDNS size"
        printf "  ${C_CHOICE}[ 3]${C_RESET} %-45s\n" "➕ Add extra tunnel domain (more speed)"
        printf "  ${C_CHOICE}[ 4]${C_RESET} %-45s\n" "➖ Remove extra tunnel domain"
        printf "  ${C_CHOICE}[ 5]${C_RESET} %-45s\n" "📃 List tunnels"
        printf "  ${C_CHOICE}[ 6]${C_RESET} %-45s\n" "🔄 Restart DNSTT + EDNS proxy"
        printf "  ${C_CHOICE}[ 7]${C_RESET} %-45s\n" "📜 View logs (last 30 lines)"
        printf "  ${C_CHOICE}[ 8]${C_RESET} %-45s\n" "♻️ Reinstall / update (binary, keys, proxy)"
        echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            return
        fi
        case $choice in
            1) show_dnstt_details; press_enter ;;
            2)
                local mtu edns
                read -p "👉 Enter MTU (e.g. 1232, 1400, 1452, 1800) [1800]: " mtu
                mtu=${mtu:-1800}
                read -p "👉 Enter EDNS size [$mtu]: " edns
                edns=${edns:-$mtu}
                echo
                run_fastdns_moded --retune "$mtu" "$edns"
                press_enter ;;
            3)
                local nd
                read -p "👉 Enter the new tunnel domain (e.g. t2.example.com): " nd
                echo
                [[ -n "$nd" ]] && run_fastdns_moded --add-tunnel "$nd"
                press_enter ;;
            4)
                local rd
                echo; run_fastdns_moded --tunnels
                echo
                read -p "👉 Enter the tunnel domain to remove: " rd
                echo
                [[ -n "$rd" ]] && run_fastdns_moded --remove-tunnel "$rd"
                press_enter ;;
            5) echo; run_fastdns_moded --tunnels; press_enter ;;
            6)
                echo -e "\n${C_BLUE}🔄 Restarting FastDns services...${C_RESET}"
                local -a svcs=(server-sldns)
                local f
                for f in /etc/systemd/system/server-sldns-*.service; do
                    [ -f "$f" ] && svcs+=("$(basename "$f" .service)")
                done
                svcs+=(edns-proxy)
                systemctl restart "${svcs[@]}"
                sleep 2
                if systemctl is-active --quiet server-sldns && systemctl is-active --quiet edns-proxy; then
                    echo -e "${C_GREEN}✅ Services restarted.${C_RESET}"
                else
                    echo -e "${C_RED}❌ A service failed to restart.${C_RESET}"
                fi
                press_enter ;;
            7)
                echo; journalctl -u server-sldns -u edns-proxy -n 30 --no-pager
                press_enter ;;
            8)
                read -p "👉 Reinstall/update FastDns now? (y/n): " rc
                if [[ "$rc" == "y" || "$rc" == "Y" ]]; then
                    run_fastdns_moded
                fi
                press_enter ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

install_dnstt() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📡 DNSTT (FastDns Moded) ---${C_RESET}"

    if [ -f "$DNSTT_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ An old visibleTech DNSTT install was found.${C_RESET}"
        echo -e "${C_DIM}It will be removed and replaced by FastDns Moded (DNSTT + EDNS proxy).${C_RESET}"
        read -p "👉 Continue? (y/n): " legacy_confirm
        if [[ "$legacy_confirm" != "y" && "$legacy_confirm" != "Y" ]]; then
            echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"
            return
        fi
        remove_legacy_dnstt
    fi

    if fastdns_installed; then
        fastdns_manage_menu
        return
    fi

    echo -e "\n${C_DIM}Ubuntu 20.04 - 26.04 and Debian 10 - 13 (apt based). Binary and keys come from the FastDns Moded repo.${C_RESET}\n"
    run_fastdns_moded
}

uninstall_dnstt() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling DNSTT (FastDns Moded) ---${C_RESET}"
    local has_new=false has_old=false
    fastdns_installed && has_new=true
    [ -f "$DNSTT_SERVICE_FILE" ] && has_old=true
    if ! $has_new && ! $has_old && [ ! -d "$FASTDNS_DIR" ]; then
        rm -rf "$FASTDNS_MODED_DIR"
        echo -e "${C_YELLOW}ℹ️ DNSTT does not appear to be installed, skipping.${C_RESET}"
        return
    fi
    local confirm="y"
    if [[ "$UNINSTALL_MODE" != "silent" ]]; then
        read -p "👉 Are you sure you want to uninstall DNSTT? (y/n): " confirm
    fi
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "\n${C_YELLOW}❌ Uninstallation cancelled.${C_RESET}"
        return
    fi
    if $has_old; then
        remove_legacy_dnstt
    fi
    if $has_new || [ -d "$FASTDNS_DIR" ]; then
        run_fastdns_moded --uninstall
    fi
    rm -rf "$FASTDNS_MODED_DIR"
    echo -e "\n${C_GREEN}✅ DNSTT has been successfully uninstalled.${C_RESET}"
}

# ====================================================================
# --- V2Ray (Xray) Manager: VMess / VLESS / Trojan over WS + gRPC ---
# nginx fronts TLS/non-TLS ports, Xray does the protocols, the limiter
# service counts bandwidth per account and switches accounts off when a
# quota or the expiry is reached. Extra files come from the FastDns
# Moded repo folder "V2RAY MODED" (see V2_REPO_BASE) with built-in
# fallbacks, so the install also works when that folder is empty.
# ====================================================================

v2() {
    FFV2_DIR="$V2_DIR" python3 "$V2_MANAGER" "$@"
}

v2ray_installed() {
    [ -f "$V2_XRAY_SERVICE_FILE" ] && [ -f "$V2_MANAGER" ]
}

write_v2ray_manager() {
    mkdir -p "$V2_LIB_DIR"
    cat > "$V2_MANAGER" <<'FF_V2RAY_PY_EOF'
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
FFV2RAY_API = 1

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
                '        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n'
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
FF_V2RAY_PY_EOF
    chmod 755 "$V2_MANAGER"
}

fetch_v2ray_manager() {
    # Built-in copy first (always works); a newer, compatible copy from the repo replaces it.
    write_v2ray_manager
    local tmp; tmp=$(mktemp)
    if curl -fsSL --retry 2 --connect-timeout 10 "$V2_REPO_BASE/ffv2ray.py" -o "$tmp" 2>/dev/null \
        && [ -s "$tmp" ] \
        && python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' "$tmp" 2>/dev/null \
        && [ "$(python3 "$tmp" api 2>/dev/null)" == "FFV2RAY-API 1" ]; then
        install -m 755 "$tmp" "$V2_MANAGER"
        echo -e "${C_GREEN}✅ Manager script loaded from the repo.${C_RESET}"
    else
        echo -e "${C_DIM}ℹ️ Using the built-in manager script (repo copy not available).${C_RESET}"
    fi
    rm -f "$tmp"
}

fetch_xray_binary() {
    local repo_name xr_arch
    case "$(uname -m)" in
        x86_64|amd64)  repo_name="xray";       xr_arch="64" ;;
        aarch64|arm64) repo_name="xray-arm64"; xr_arch="arm64-v8a" ;;
        armv7l|armv6l) repo_name="xray-arm32"; xr_arch="arm32-v7a" ;;
        i?86)          repo_name="xray-32";    xr_arch="32" ;;
        *) echo -e "${C_RED}❌ Unsupported CPU: $(uname -m)${C_RESET}"; return 1 ;;
    esac
    mkdir -p "$V2_LIB_DIR"
    local new="$V2_XRAY_BIN.new"
    rm -f "$new"

    # 1) repo folder (same repo as FastDns Moded)
    if curl -fsSL --retry 2 --connect-timeout 10 "$V2_REPO_BASE/$repo_name" -o "$new" 2>/dev/null \
        && [ -s "$new" ] && [ "$(head -c4 "$new" 2>/dev/null | tail -c3)" == "ELF" ]; then
        chmod 755 "$new"
        if "$new" version >/dev/null 2>&1; then
            mv -f "$new" "$V2_XRAY_BIN"
            echo -e "${C_GREEN}✅ Xray core loaded from the repo.${C_RESET}"
            return 0
        fi
    fi
    rm -f "$new"

    # 2) official Xray-core release
    echo -e "${C_DIM}ℹ️ Repo has no usable Xray binary, using the official Xray-core release...${C_RESET}"
    local tmpd; tmpd=$(mktemp -d)
    if curl -fsSL --retry 3 --connect-timeout 15 \
        "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${xr_arch}.zip" -o "$tmpd/xray.zip" \
        && python3 -c 'import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extract("xray", sys.argv[2])' "$tmpd/xray.zip" "$tmpd" \
        && [ -s "$tmpd/xray" ]; then
        install -m 755 "$tmpd/xray" "$new"
        if "$new" version >/dev/null 2>&1; then
            mv -f "$new" "$V2_XRAY_BIN"
            rm -rf "$tmpd"
            echo -e "${C_GREEN}✅ Xray core installed: $("$V2_XRAY_BIN" version 2>/dev/null | head -n 1)${C_RESET}"
            return 0
        fi
    fi
    rm -rf "$tmpd" "$new"
    echo -e "${C_RED}❌ Could not download a working Xray binary.${C_RESET}"
    return 1
}

write_v2ray_units() {
    local py nginx_bin
    py=$(command -v python3)
    nginx_bin=$(command -v nginx || echo /usr/sbin/nginx)

    cat > "$V2_XRAY_SERVICE_FILE" <<EOF
[Unit]
Description=visibleTech Xray (VMess/VLESS/Trojan)
After=network.target

[Service]
Type=simple
User=root
ExecStart=$V2_XRAY_BIN run -config $V2_DIR/config.json
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    cat > "$V2_NGINX_SERVICE_FILE" <<EOF
[Unit]
Description=visibleTech V2Ray nginx front (WS/gRPC, TLS)
After=network.target ff-xray.service

[Service]
Type=simple
User=root
ExecStartPre=$nginx_bin -t -c $V2_DIR/nginx.conf
ExecStart=$nginx_bin -c $V2_DIR/nginx.conf -g 'daemon off;'
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    cat > "$V2_LIMITER_SERVICE_FILE" <<EOF
[Unit]
Description=visibleTech V2Ray bandwidth limiter and live counter
After=ff-xray.service

[Service]
Type=simple
User=root
Environment=FFV2_DIR=$V2_DIR
ExecStart=$py $V2_MANAGER daemon
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    if [ -d /etc/logrotate.d ]; then
        cat > /etc/logrotate.d/visibleTech-xray <<EOF
/var/log/xray/*.log {
    daily
    maxsize 20M
    rotate 3
    missingok
    notifempty
    copytruncate
    compress
}
EOF
    fi
    systemctl daemon-reload
}

install_v2ray() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🛰️ Install V2Ray (Xray): VMess / VLESS / Trojan ---${C_RESET}"

    if v2ray_installed; then
        v2ray_manager_menu
        return
    fi

    echo -e "\n${C_DIM}WS + gRPC on one TLS port and one non-TLS port, bandwidth limits per account.${C_RESET}"
    local def_domain v2_domain tls_port http_port
    def_domain=$(detect_preferred_host)
    read -p "👉 Enter your domain (its A record must point to this server) [$def_domain]: " v2_domain
    v2_domain=${v2_domain:-$def_domain}
    if [[ -z "$v2_domain" || ! "$v2_domain" =~ ^[A-Za-z0-9.-]+$ ]]; then
        echo -e "\n${C_RED}❌ Invalid domain.${C_RESET}"; return
    fi
    read -p "👉 TLS port [443]: " tls_port
    tls_port=${tls_port:-443}
    read -p "👉 Non-TLS port [80]: " http_port
    http_port=${http_port:-80}
    if ! _valid_port "$tls_port" || ! _valid_port "$http_port" || [[ "$tls_port" == "$http_port" ]]; then
        echo -e "\n${C_RED}❌ Ports must be two different numbers between 1 and 65535.${C_RESET}"; return
    fi
    echo -e "${C_DIM}ℹ️ If the WebSocket proxy or Stunnel already use these ports, pick other ports here or stop them first.${C_RESET}"

    local nginx_pre=false
    if systemctl is-active --quiet nginx || systemctl is-enabled --quiet nginx 2>/dev/null; then
        nginx_pre=true
    fi

    echo -e "\n${C_BLUE}📦 Installing nginx, python3, curl and openssl...${C_RESET}"
    ff_pkg_install nginx python3 curl openssl || {
        echo -e "${C_RED}❌ Failed to install the required packages.${C_RESET}"; return
    }
    if ! command -v nginx &>/dev/null; then
        echo -e "${C_RED}❌ nginx binary not found after installation.${C_RESET}"; return
    fi
    # we run our own nginx instance; the packaged default one must not hold port 80
    if ! $nginx_pre; then
        systemctl disable --now nginx >/dev/null 2>&1
    fi

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$V2_DIR"
    ST_CERT_MODE=""; ST_CERT_DOMAIN=""; ST_CERT_EMAIL=""
    echo -e "${C_DIM}Tip: use ${v2_domain} as the certificate name.${C_RESET}"
    select_stunnel_certificate || return

    check_and_free_ports "$tls_port" "$http_port" || return
    check_and_open_firewall_port "$tls_port" tcp
    check_and_open_firewall_port "$http_port" tcp

    echo -e "\n${C_BLUE}📥 Fetching the Xray core and the manager...${C_RESET}"
    fetch_xray_binary || return
    fetch_v2ray_manager

    echo -e "\n${C_GREEN}📝 Writing configuration and services...${C_RESET}"
    v2 init --domain "$v2_domain" --tls-port "$tls_port" --http-port "$http_port" \
        --cert "$SSL_CERT_CHAIN_FILE" --key "$SSL_CERT_KEY_FILE" \
        --xray-bin "$V2_XRAY_BIN" --nginx-bin "$(command -v nginx)" >/dev/null || {
        echo -e "${C_RED}❌ Could not write the V2Ray settings.${C_RESET}"; return
    }
    echo "NGINX_PREEXISTING=\"$nginx_pre\"" > "$V2_DIR/install.conf"
    if [[ "$ST_CERT_MODE" == "certbot" ]] || [ -d /etc/letsencrypt/renewal-hooks/deploy ]; then
        mkdir -p /etc/letsencrypt/renewal-hooks/deploy
        printf '#!/bin/bash\nsystemctl reload %s 2>/dev/null || systemctl restart %s 2>/dev/null\n' \
            "$V2_NGINX_SERVICE" "$V2_NGINX_SERVICE" > /etc/letsencrypt/renewal-hooks/deploy/visibleTech-v2ray.sh
        chmod 755 /etc/letsencrypt/renewal-hooks/deploy/visibleTech-v2ray.sh
    fi
    write_v2ray_units
    systemctl enable "$V2_XRAY_SERVICE" "$V2_NGINX_SERVICE" "$V2_LIMITER_SERVICE" >/dev/null 2>&1
    systemctl restart "$V2_XRAY_SERVICE" "$V2_NGINX_SERVICE" "$V2_LIMITER_SERVICE"
    sleep 3

    local ok=true
    for svc in "$V2_XRAY_SERVICE" "$V2_NGINX_SERVICE" "$V2_LIMITER_SERVICE"; do
        if systemctl is-active --quiet "$svc"; then
            echo -e "  ${C_GREEN}✅ $svc is active${C_RESET}"
        else
            echo -e "  ${C_RED}❌ $svc failed to start${C_RESET}"
            journalctl -u "$svc" -n 8 --no-pager 2>/dev/null | sed 's/^/      /'
            ok=false
        fi
    done
    if $ok; then
        echo -e "\n${C_GREEN}✅ SUCCESS: V2Ray (Xray) is installed.${C_RESET}"
        echo -e "   • Domain:       ${C_YELLOW}$v2_domain${C_RESET}"
        echo -e "   • TLS port:     ${C_YELLOW}$tls_port${C_RESET}   (WS + gRPC)"
        echo -e "   • Non-TLS port: ${C_YELLOW}$http_port${C_RESET}   (WS)"
        echo -e "   • Create accounts in: ${C_CYAN}Main Menu > V2Ray (Xray) Manager${C_RESET}"
        if [[ "$ST_CERT_MODE" == "self-signed" ]]; then
            echo -e "   ${C_YELLOW}⚠️ Self-signed certificate: clients must enable 'allow insecure'.${C_RESET}"
        fi
    fi
}

update_v2ray() {
    echo -e "\n${C_BLUE}♻️ Updating the Xray core and the manager (accounts are kept)...${C_RESET}"
    systemctl stop "$V2_XRAY_SERVICE" "$V2_LIMITER_SERVICE" >/dev/null 2>&1
    fetch_xray_binary || { systemctl start "$V2_XRAY_SERVICE" "$V2_LIMITER_SERVICE" >/dev/null 2>&1; return; }
    fetch_v2ray_manager
    write_v2ray_units
    v2 render --restart >/dev/null
    systemctl restart "$V2_XRAY_SERVICE" "$V2_NGINX_SERVICE" "$V2_LIMITER_SERVICE"
    sleep 2
    if systemctl is-active --quiet "$V2_XRAY_SERVICE"; then
        echo -e "${C_GREEN}✅ Updated and running.${C_RESET}"
    else
        echo -e "${C_RED}❌ Xray did not start after the update.${C_RESET}"
        journalctl -u "$V2_XRAY_SERVICE" -n 10 --no-pager
    fi
}

uninstall_v2ray() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling V2Ray (Xray) ---${C_RESET}"
    if ! v2ray_installed && [ ! -d "$V2_DIR" ] && [ ! -d "$V2_LIB_DIR" ]; then
        echo -e "${C_YELLOW}ℹ️ V2Ray is not installed, skipping.${C_RESET}"
        return
    fi
    local confirm="y" purge_nginx="n" NGINX_PREEXISTING="true"
    if [[ "$UNINSTALL_MODE" != "silent" ]]; then
        read -p "👉 This deletes ALL V2Ray accounts and their bandwidth counters. Continue? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo -e "\n${C_YELLOW}❌ Uninstallation cancelled.${C_RESET}"; return
        fi
    fi
    [ -f "$V2_DIR/install.conf" ] && source "$V2_DIR/install.conf"
    echo -e "${C_BLUE}🛑 Stopping services...${C_RESET}"
    systemctl stop "$V2_LIMITER_SERVICE" "$V2_NGINX_SERVICE" "$V2_XRAY_SERVICE" >/dev/null 2>&1
    systemctl disable "$V2_LIMITER_SERVICE" "$V2_NGINX_SERVICE" "$V2_XRAY_SERVICE" >/dev/null 2>&1
    rm -f "$V2_XRAY_SERVICE_FILE" "$V2_NGINX_SERVICE_FILE" "$V2_LIMITER_SERVICE_FILE" \
          /etc/logrotate.d/visibleTech-xray /etc/letsencrypt/renewal-hooks/deploy/visibleTech-v2ray.sh
    rm -rf "$V2_LIB_DIR" "$V2_DIR" /var/log/xray
    systemctl daemon-reload
    if [[ "$NGINX_PREEXISTING" != "true" ]]; then
        if [[ "$UNINSTALL_MODE" == "silent" ]]; then
            purge_nginx="y"
        else
            read -p "👉 Also remove the nginx package (installed for V2Ray)? (y/n): " purge_nginx
        fi
        if [[ "$purge_nginx" == "y" || "$purge_nginx" == "Y" ]]; then
            ff_pkg_purge nginx nginx-common >/dev/null 2>&1
            ff_pkg_autoremove
            echo -e "${C_GREEN}🗑️ nginx package removed.${C_RESET}"
        fi
    fi
    echo -e "${C_GREEN}✅ V2Ray (Xray) has been uninstalled.${C_RESET}"
}

# ---------------------------------------------------------------- account helpers
V2_SELECTED=""

_v2_pick_user() {   # $1 = proto (or empty for all)   $2 = title
    V2_SELECTED=""
    local proto="$1" title="$2"
    local -a rows=()
    if [[ -n "$proto" ]]; then
        mapfile -t rows < <(v2 names --proto "$proto")
    else
        mapfile -t rows < <(v2 names)
    fi
    if (( ${#rows[@]} == 0 )); then
        echo -e "\n${C_YELLOW}ℹ️ No accounts found.${C_RESET}"
        V2_SELECTED="NO_USERS"
        return
    fi
    echo -e "\n${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    local i=1 line n p s e rest
    for line in "${rows[@]}"; do
        IFS='|' read -r n p s e rest <<< "$line"
        printf "  ${C_CHOICE}[%2d]${C_RESET} %-14s %-6s %-9s %s\n" "$i" "$n" "$p" "$s" "$rest"
        i=$((i + 1))
    done
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} Cancel\n"
    local pick
    read -p "👉 Select account number: " pick
    if ! [[ "$pick" =~ ^[0-9]+$ ]] || (( pick < 1 || pick > ${#rows[@]} )); then
        return
    fi
    IFS='|' read -r V2_SELECTED _ <<< "${rows[$((pick - 1))]}"
}

_v2_num() {   # validates a non-negative number
    [[ "$1" =~ ^[0-9]+\.?[0-9]*$ ]]
}

v2_create_account() {
    local proto="$1" label="$2" name days total daily
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create XRAY $label WS Account ---${C_RESET}"
    read -p "👤 Username (or '0' to cancel): " name
    if [[ "$name" == "0" ]]; then echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; return; fi
    if ! [[ "$name" =~ ^[A-Za-z0-9_-]{2,24}$ ]]; then
        echo -e "\n${C_RED}❌ Username must be 2-24 characters: letters, digits, _ or -${C_RESET}"; return
    fi
    if v2 exists "$name"; then
        echo -e "\n${C_RED}❌ Account '$name' already exists.${C_RESET}"; return
    fi
    read -p "🗓️ Account duration in days [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]] || (( days < 1 )); then echo -e "\n${C_RED}❌ Invalid number of days.${C_RESET}"; return; fi
    read -p "📦 Total bandwidth limit in GB (0 = unlimited) [0]: " total
    total=${total:-0}
    if ! _v2_num "$total"; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    read -p "📦 DAILY bandwidth limit in GB (0 = unlimited) [0]: " daily
    daily=${daily:-0}
    if ! _v2_num "$daily"; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    v2 add --proto "$proto" --name "$name" --days "$days" --total "$total" --daily "$daily" >/dev/null || return
    clear; show_banner
    echo -e "${C_GREEN}✅ Account '$name' created!${C_RESET}"
    v2 show "$name"
    echo -e "\n${C_DIM}Bandwidth is counted live and the account is switched off automatically when the limit or expiry is reached.${C_RESET}"
}

v2_trial_account() {
    local proto="$1" label="$2" choice hours name total
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ⏱️ Trial XRAY $label WS ---${C_RESET}"
    echo -e "\n${C_CYAN}Select trial duration:${C_RESET}\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} ⏱️  1 Hour\n  ${C_GREEN}[ 2]${C_RESET} ⏱️  3 Hours\n  ${C_GREEN}[ 3]${C_RESET} ⏱️  6 Hours\n"
    printf "  ${C_GREEN}[ 4]${C_RESET} ⏱️  12 Hours\n  ${C_GREEN}[ 5]${C_RESET} 📅  1 Day\n  ${C_GREEN}[ 6]${C_RESET} ⚙️  Custom (hours)\n"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ↩️ Cancel\n"
    read -p "👉 Select duration: " choice
    case $choice in
        1) hours=1 ;; 2) hours=3 ;; 3) hours=6 ;; 4) hours=12 ;; 5) hours=24 ;;
        6) read -p "👉 Enter hours: " hours
           if ! [[ "$hours" =~ ^[0-9]+$ ]] || (( hours < 1 )); then echo -e "\n${C_RED}❌ Invalid hours.${C_RESET}"; return; fi ;;
        *) echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; return ;;
    esac
    local default_name="trial_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
    read -p "👤 Username [$default_name]: " name
    name=${name:-$default_name}
    if ! [[ "$name" =~ ^[A-Za-z0-9_-]{2,24}$ ]]; then echo -e "\n${C_RED}❌ Invalid username.${C_RESET}"; return; fi
    if v2 exists "$name"; then echo -e "\n${C_RED}❌ Account '$name' already exists.${C_RESET}"; return; fi
    read -p "📦 Bandwidth limit in GB (0 = unlimited) [1]: " total
    total=${total:-1}
    if ! _v2_num "$total"; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    v2 add --proto "$proto" --name "$name" --hours "$hours" --total "$total" --daily 0 --trial >/dev/null || return
    clear; show_banner
    echo -e "${C_GREEN}✅ Trial account '$name' created for $hours hour(s).${C_RESET}"
    v2 show "$name"
    echo -e "\n${C_DIM}Trial accounts are deleted automatically when they expire.${C_RESET}"
}

v2_renew_account() {
    local proto="$1" label="$2" days reset_ans
    clear; show_banner
    _v2_pick_user "$proto" "--- 🔄 Extending XRAY $label WS Active ---"
    [[ -z "$V2_SELECTED" || "$V2_SELECTED" == "NO_USERS" ]] && return
    read -p "🗓️ Days to add [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]] || (( days < 1 )); then echo -e "\n${C_RED}❌ Invalid number of days.${C_RESET}"; return; fi
    read -p "♻️ Reset the bandwidth counters to zero? (y/n) [n]: " reset_ans
    if [[ "$reset_ans" == "y" || "$reset_ans" == "Y" ]]; then
        v2 renew "$V2_SELECTED" --days "$days" --reset >/dev/null || return
    else
        v2 renew "$V2_SELECTED" --days "$days" >/dev/null || return
    fi
    echo -e "\n${C_GREEN}✅ '$V2_SELECTED' extended by $days day(s).${C_RESET}"
    v2 usage "$V2_SELECTED"
}

v2_delete_account() {
    local proto="$1" label="$2" confirm
    clear; show_banner
    _v2_pick_user "$proto" "--- 🗑️ Delete XRAY $label WS ---"
    [[ -z "$V2_SELECTED" || "$V2_SELECTED" == "NO_USERS" ]] && return
    read -p "👉 Delete '$V2_SELECTED'? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        v2 del "$V2_SELECTED" >/dev/null && echo -e "\n${C_GREEN}✅ '$V2_SELECTED' deleted.${C_RESET}"
    else
        echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"
    fi
}

v2_lock_toggle() {
    local proto="$1" label="$2" st
    clear; show_banner
    _v2_pick_user "$proto" "--- 🔒 Lock / Unlock XRAY $label WS ---"
    [[ -z "$V2_SELECTED" || "$V2_SELECTED" == "NO_USERS" ]] && return
    st=$(v2 names --proto "$proto" | awk -F'|' -v u="$V2_SELECTED" '$1==u{print $3}')
    if [[ "$st" == "locked" ]]; then
        v2 unlock "$V2_SELECTED" >/dev/null && echo -e "\n${C_GREEN}🔓 '$V2_SELECTED' unlocked.${C_RESET}"
    else
        v2 lock "$V2_SELECTED" >/dev/null && echo -e "\n${C_YELLOW}🔒 '$V2_SELECTED' locked.${C_RESET}"
    fi
}

v2_edit_limits() {
    local proto="$1" label="$2" total daily reset_ans
    clear; show_banner
    _v2_pick_user "$proto" "--- ✏️ Edit bandwidth limit: XRAY $label WS ---"
    [[ -z "$V2_SELECTED" || "$V2_SELECTED" == "NO_USERS" ]] && return
    echo
    v2 usage "$V2_SELECTED"
    echo
    read -p "📦 New TOTAL limit in GB (0 = unlimited, Enter = keep): " total
    read -p "📦 New DAILY limit in GB (0 = unlimited, Enter = keep): " daily
    local -a args=()
    if [[ -n "$total" ]]; then _v2_num "$total" || { echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; }; args+=(--total "$total"); fi
    if [[ -n "$daily" ]]; then _v2_num "$daily" || { echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; }; args+=(--daily "$daily"); fi
    read -p "♻️ Reset the used-data counters to zero? (y/n) [n]: " reset_ans
    [[ "$reset_ans" == "y" || "$reset_ans" == "Y" ]] && args+=(--reset)
    if (( ${#args[@]} == 0 )); then echo -e "\n${C_YELLOW}ℹ️ Nothing changed.${C_RESET}"; return; fi
    v2 limit "$V2_SELECTED" "${args[@]}" >/dev/null && echo -e "\n${C_GREEN}✅ Limits updated.${C_RESET}"
}

v2_show_account() {
    local proto="$1" label="$2"
    clear; show_banner
    _v2_pick_user "$proto" "--- 📋 Show XRAY $label WS Account ---"
    [[ -z "$V2_SELECTED" || "$V2_SELECTED" == "NO_USERS" ]] && return
    v2 show "$V2_SELECTED"
}

v2_bandwidth_details() {
    local proto="$1" label="$2"
    clear; show_banner
    _v2_pick_user "$proto" "--- 📊 Bandwidth: XRAY $label WS ---"
    [[ -z "$V2_SELECTED" || "$V2_SELECTED" == "NO_USERS" ]] && return
    v2 usage "$V2_SELECTED"
}

v2ray_proto_menu() {
    local proto="$1" label="$2"
    while true; do
        clear; show_banner
        echo -e "${C_CYAN}┌────────────────────────────────────────────────┐${C_RESET}"
        echo -e "\n    ${C_BOLD}XRAY ${label^^} WS BY visibleTech${C_RESET}\n"
        echo -e "    ${C_CHOICE}[01]${C_RESET} Create XRAY $label WS"
        echo -e "    ${C_CHOICE}[02]${C_RESET} Trial XRAY $label WS"
        echo -e "    ${C_CHOICE}[03]${C_RESET} Extending XRAY $label WS Active"
        echo -e "    ${C_CHOICE}[04]${C_RESET} Delete XRAY $label WS"
        echo -e "    ${C_CHOICE}[05]${C_RESET} Check User Login XRAY $label WS"
        echo -e "    ${C_CHOICE}[06]${C_RESET} List accounts + live bandwidth"
        echo -e "    ${C_CHOICE}[07]${C_RESET} Show account / links"
        echo -e "    ${C_CHOICE}[08]${C_RESET} Lock / Unlock account"
        echo -e "    ${C_CHOICE}[09]${C_RESET} Edit bandwidth limit"
        echo -e "    ${C_CHOICE}[10]${C_RESET} Bandwidth details (progress bar)"
        echo -e "\n${C_CYAN}└────────────────────────────────────────────────┘${C_RESET}\n"
        echo -e "    ${C_WARN}[00]${C_RESET} Main Menu\n"
        local opt
        if ! read -r -p "$(echo -e ${C_PROMPT}"Select menu : "${C_RESET})" opt; then echo; return; fi
        case $opt in
            1|01) v2_create_account "$proto" "$label"; press_enter ;;
            2|02) v2_trial_account "$proto" "$label"; press_enter ;;
            3|03) v2_renew_account "$proto" "$label"; press_enter ;;
            4|04) v2_delete_account "$proto" "$label"; press_enter ;;
            5|05) echo; v2 online --proto "$proto"; press_enter ;;
            6|06) echo; v2 list --proto "$proto"; press_enter ;;
            7|07) v2_show_account "$proto" "$label"; press_enter ;;
            8|08) v2_lock_toggle "$proto" "$label"; press_enter ;;
            9|09) v2_edit_limits "$proto" "$label"; press_enter ;;
            10) v2_bandwidth_details "$proto" "$label"; press_enter ;;
            0|00) return ;;
            *) invalid_option ;;
        esac
    done
}

v2ray_settings_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- ⚙️ V2Ray Settings ---${C_RESET}"
        echo -e "\n  ${C_CYAN}Domain:${C_RESET}       ${C_YELLOW}$(v2 get domain)${C_RESET}"
        echo -e "  ${C_CYAN}TLS port:${C_RESET}     ${C_YELLOW}$(v2 get tls_port)${C_RESET}"
        echo -e "  ${C_CYAN}Non-TLS port:${C_RESET} ${C_YELLOW}$(v2 get http_port)${C_RESET}"
        echo -e "  ${C_CYAN}Certificate:${C_RESET}  ${C_YELLOW}$(v2 get cert)${C_RESET}"
        echo -e "  ${C_CYAN}Xray core:${C_RESET}    ${C_YELLOW}$("$V2_XRAY_BIN" version 2>/dev/null | head -n 1)${C_RESET}"
        echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
        printf "  ${C_CHOICE}[ 1]${C_RESET} %s\n" "🌐 Change domain"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %s\n" "🔌 Change ports"
        printf "  ${C_CHOICE}[ 3]${C_RESET} %s\n" "🔐 Replace / renew certificate"
        echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return\n"
        local opt
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" opt; then echo; return; fi
        case $opt in
            1)
                local nd
                read -p "👉 New domain: " nd
                if [[ -n "$nd" && "$nd" =~ ^[A-Za-z0-9.-]+$ ]]; then
                    v2 init --domain "$nd" >/dev/null && echo -e "\n${C_GREEN}✅ Domain changed. Existing links must be re-shared (use 'Show account').${C_RESET}"
                else
                    echo -e "\n${C_RED}❌ Invalid domain.${C_RESET}"
                fi
                press_enter ;;
            2)
                local nt nh
                read -p "👉 New TLS port [$(v2 get tls_port)]: " nt;  nt=${nt:-$(v2 get tls_port)}
                read -p "👉 New non-TLS port [$(v2 get http_port)]: " nh; nh=${nh:-$(v2 get http_port)}
                if ! _valid_port "$nt" || ! _valid_port "$nh" || [[ "$nt" == "$nh" ]]; then
                    echo -e "\n${C_RED}❌ Invalid ports.${C_RESET}"
                else
                    systemctl stop "$V2_NGINX_SERVICE" >/dev/null 2>&1
                    if check_and_free_ports "$nt" "$nh" && check_and_open_firewall_port "$nt" tcp && check_and_open_firewall_port "$nh" tcp; then
                        v2 init --tls-port "$nt" --http-port "$nh" >/dev/null
                        systemctl restart "$V2_NGINX_SERVICE"
                        echo -e "\n${C_GREEN}✅ Ports changed. Existing links must be re-shared.${C_RESET}"
                    else
                        systemctl start "$V2_NGINX_SERVICE" >/dev/null 2>&1
                    fi
                fi
                press_enter ;;
            3)
                systemctl stop "$V2_NGINX_SERVICE" >/dev/null 2>&1
                ST_CERT_MODE=""; ST_CERT_DOMAIN=""; ST_CERT_EMAIL=""
                if select_stunnel_certificate; then
                    echo -e "${C_GREEN}✅ Certificate updated.${C_RESET}"
                fi
                systemctl restart "$V2_NGINX_SERVICE"
                press_enter ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

v2ray_manager_menu() {
    while true; do
        clear; show_banner
        local n_vmess=0 n_vless=0 n_trojan=0
        read -r n_vmess n_vless n_trojan <<< "$(v2 counts 2>/dev/null | sed 's/[a-z]*=//g')"
        local sx sn sl
        systemctl is-active --quiet "$V2_XRAY_SERVICE"   && sx="${C_STATUS_A}ON${C_RESET}"  || sx="${C_STATUS_I}OFF${C_RESET}"
        systemctl is-active --quiet "$V2_NGINX_SERVICE"  && sn="${C_STATUS_A}ON${C_RESET}"  || sn="${C_STATUS_I}OFF${C_RESET}"
        systemctl is-active --quiet "$V2_LIMITER_SERVICE" && sl="${C_STATUS_A}ON${C_RESET}" || sl="${C_STATUS_I}OFF${C_RESET}"
        echo -e "${C_CYAN}┌────────────────────────────────────────────────┐${C_RESET}"
        echo -e "\n    ${C_BOLD}XRAY / V2RAY MANAGER${C_RESET}\n"
        echo -e "    ${C_CYAN}Core   :${C_RESET} $("$V2_XRAY_BIN" version 2>/dev/null | head -n 1 | cut -c1-40)"
        echo -e "    ${C_CYAN}Domain :${C_RESET} $(v2 get domain)   TLS $(v2 get tls_port) / none-TLS $(v2 get http_port)\n"
        echo -e "${C_CYAN}└────────────────────────────────────────────────┘${C_RESET}"
        echo -e "      VMESS ${C_YELLOW}${n_vmess:-0}${C_RESET}    VLESS ${C_YELLOW}${n_vless:-0}${C_RESET}    TROJAN ${C_YELLOW}${n_trojan:-0}${C_RESET}"
        echo -e "      XRAY : $sx   NGINX : $sn   LIMITER : $sl"
        echo -e "${C_CYAN}┌────────────────────────────────────────────────┐${C_RESET}\n"
        echo -e "    ${C_CHOICE}[01]${C_RESET} VMESS     ${C_CYAN}[Menu]${C_RESET}     ${C_CHOICE}[06]${C_RESET} LIVE BANDWIDTH"
        echo -e "    ${C_CHOICE}[02]${C_RESET} VLESS     ${C_CYAN}[Menu]${C_RESET}     ${C_CHOICE}[07]${C_RESET} ALL ACCOUNTS"
        echo -e "    ${C_CHOICE}[03]${C_RESET} TROJAN    ${C_CYAN}[Menu]${C_RESET}     ${C_CHOICE}[08]${C_RESET} CHECK LOGIN (ALL)"
        echo -e "    ${C_CHOICE}[04]${C_RESET} SETTING   ${C_CYAN}[Menu]${C_RESET}     ${C_CHOICE}[09]${C_RESET} CLEANUP EXPIRED"
        echo -e "    ${C_CHOICE}[05]${C_RESET} RESTART ALL         ${C_CHOICE}[10]${C_RESET} VIEW LOGS"
        echo -e "    ${C_CHOICE}[11]${C_RESET} UPDATE XRAY CORE    ${C_CHOICE}[12]${C_RESET} UNINSTALL"
        echo -e "\n${C_CYAN}└────────────────────────────────────────────────┘${C_RESET}\n"
        echo -e "    ${C_WARN}[00]${C_RESET} Return\n"
        local opt
        if ! read -r -p "$(echo -e ${C_PROMPT}"Select menu : "${C_RESET})" opt; then echo; return; fi
        case $opt in
            1|01) v2ray_proto_menu vmess Vmess ;;
            2|02) v2ray_proto_menu vless Vless ;;
            3|03) v2ray_proto_menu trojan Trojan ;;
            4|04) v2ray_settings_menu ;;
            5|05)
                systemctl restart "$V2_XRAY_SERVICE" "$V2_NGINX_SERVICE" "$V2_LIMITER_SERVICE"
                sleep 2
                echo -e "\n${C_GREEN}✅ Services restarted.${C_RESET}"; press_enter ;;
            6|06) v2 monitor ;;
            7|07) echo; v2 list; press_enter ;;
            8|08) echo; v2 online; press_enter ;;
            9|09) echo; v2 cleanup; press_enter ;;
            10) echo; journalctl -u "$V2_XRAY_SERVICE" -u "$V2_NGINX_SERVICE" -u "$V2_LIMITER_SERVICE" -n 30 --no-pager; press_enter ;;
            11) update_v2ray; press_enter ;;
            12) uninstall_v2ray; press_enter; v2ray_installed || return ;;
            0|00) return ;;
            *) invalid_option ;;
        esac
    done
}

v2ray_entry() {
    if v2ray_installed; then
        v2ray_manager_menu
    else
        install_v2ray
        press_enter
    fi
}

# --- ZiVPN Installation Logic ---
install_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing ZiVPN (UDP/VPN) ---${C_RESET}"
    
    if [ -f "$ZIVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ ZiVPN is already installed.${C_RESET}"
        return
    fi

    if [ ! -f "$BADVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ ZiVPN requires the badvpn (udpgw) backend to provide internet access.${C_RESET}"
        echo -e "${C_GREEN}📦 Automatically installing badvpn backend...${C_RESET}"
        sleep 2
        install_badvpn
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Resuming ZiVPN Installation ---${C_RESET}"
    fi

    check_and_free_ports 5667 || return
    check_and_open_firewall_port 5667 udp || return
    check_and_open_firewall_port_range "6000:19999" udp || return

    echo -e "\n${C_GREEN}⚙️ Checking system architecture...${C_RESET}"
    local arch=$(uname -m)
    local zivpn_url=""
    
    if [[ "$arch" == "x86_64" ]]; then
        zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
        echo -e "${C_BLUE}ℹ️ Detected AMD64/x86_64 architecture.${C_RESET}"
    elif [[ "$arch" == "aarch64" ]]; then
        zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
        echo -e "${C_BLUE}ℹ️ Detected ARM64 architecture.${C_RESET}"
    elif [[ "$arch" == "armv7l" || "$arch" == "arm" ]]; then
         zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm"
         echo -e "${C_BLUE}ℹ️ Detected ARM architecture.${C_RESET}"
    else
        echo -e "${C_RED}❌ Unsupported architecture: $arch${C_RESET}"
        return
    fi

    echo -e "\n${C_GREEN}📦 Downloading ZiVPN binary...${C_RESET}"
    if ! wget -q --show-progress -O "$ZIVPN_BIN" "$zivpn_url"; then
        echo -e "${C_RED}❌ Download failed. Check internet connection.${C_RESET}"
        return
    fi
    chmod +x "$ZIVPN_BIN"

    echo -e "\n${C_GREEN}⚙️ Configuring ZIVPN...${C_RESET}"
    mkdir -p "$ZIVPN_DIR"
    
    # Generate Certificates
    echo -e "${C_BLUE}🔐 Generating self-signed certificates...${C_RESET}"
    if ! command -v openssl &>/dev/null; then
        ff_pkg_install openssl >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to install openssl for ZiVPN certificate generation.${C_RESET}"
            return
        }
    fi
    
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" \
        -keyout "$ZIVPN_KEY_FILE" -out "$ZIVPN_CERT_FILE" 2>/dev/null

    if [ ! -f "$ZIVPN_CERT_FILE" ]; then
        echo -e "${C_RED}❌ Failed to generate certificates.${C_RESET}"
        return
    fi

    # System Tuning
    echo -e "${C_BLUE}🔧 Tuning system network parameters...${C_RESET}"
    sysctl -w net.core.rmem_max=16777216 >/dev/null
    sysctl -w net.core.wmem_max=16777216 >/dev/null

    # Create Service
    echo -e "${C_BLUE}📝 Creating systemd service file...${C_RESET}"
    cat <<EOF > "$ZIVPN_SERVICE_FILE"
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$ZIVPN_DIR
ExecStart=$ZIVPN_BIN server -c $ZIVPN_CONFIG_FILE
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    # Configure Passwords
    echo -e "\n${C_YELLOW}🔑 ZiVPN Password Setup${C_RESET}"
    read -p "👉 Enter passwords separated by commas (e.g., user1,user2) [Default: 'zi']: " input_config
    
    if [ -n "$input_config" ]; then
        IFS=',' read -r -a config_array <<< "$input_config"
        # Ensure array format for JSON
        json_passwords=$(printf '"%s",' "${config_array[@]}")
        json_passwords="[${json_passwords%,}]"
    else
        json_passwords='["zi"]'
    fi

    # Create Config File
    cat <<EOF > "$ZIVPN_CONFIG_FILE"
{
  "listen": ":5667",
   "cert": "$ZIVPN_CERT_FILE",
   "key": "$ZIVPN_KEY_FILE",
   "obfs":"zivpn",
   "auth": {
    "mode": "passwords", 
    "config": $json_passwords
  }
}
EOF

    echo -e "\n${C_GREEN}🚀 Starting ZiVPN Service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable zivpn.service
    systemctl start zivpn.service

    # Port Forwarding / Firewall
    echo -e "${C_BLUE}🔥 Configuring Firewall Rules (Redirecting 6000-19999 -> 5667)...${C_RESET}"
    
    # Determine primary interface
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    
    if [ -n "$iface" ]; then
        iptables -t nat -C PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || \
            iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
        # Note: IPTables rules are not persistent by default without iptables-persistent package
    else
        echo -e "${C_YELLOW}⚠️ Could not detect default interface for IPTables redirection.${C_RESET}"
    fi

    # Cleanup
    rm -f zi.sh zi2.sh 2>/dev/null

    if systemctl is-active --quiet zivpn.service; then
        echo -e "\n${C_GREEN}✅ ZiVPN Installed Successfully!${C_RESET}"
        echo -e "   - UDP Port: 5667 (Direct)"
        echo -e "   - UDP Ports: 6000-19999 (Forwarded)"
    else
        echo -e "\n${C_RED}❌ ZiVPN Service failed to start. Check logs: journalctl -u zivpn.service${C_RESET}"
    fi
}

uninstall_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Uninstall ZiVPN ---${C_RESET}"
    
    if [ ! -f "$ZIVPN_SERVICE_FILE" ] && [ ! -f "$ZIVPN_BIN" ]; then
        echo -e "\n${C_YELLOW}ℹ️ ZiVPN does not appear to be installed.${C_RESET}"
        return
    fi

    read -p "👉 Are you sure you want to uninstall ZiVPN? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "${C_YELLOW}Cancelled.${C_RESET}"; return; fi

    echo -e "\n${C_BLUE}🛑 Stopping services...${C_RESET}"
    systemctl stop zivpn.service 2>/dev/null
    systemctl disable zivpn.service 2>/dev/null

    local iface
    iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    if [ -n "$iface" ]; then
        iptables -t nat -D PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || true
    fi
    
    echo -e "${C_BLUE}🗑️ Removing files...${C_RESET}"
    rm -f "$ZIVPN_SERVICE_FILE"
    rm -rf "$ZIVPN_DIR"
    rm -f "$ZIVPN_BIN"
    
    systemctl daemon-reload
    
    # Clean cache (from original uninstall script logic)
    echo -e "${C_BLUE}🧹 Cleaning memory cache...${C_RESET}"
    sync; echo 3 > /proc/sys/vm/drop_caches

    echo -e "\n${C_GREEN}✅ ZiVPN Uninstalled Successfully.${C_RESET}"
}

install_panel_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💻 Install X-UI / 3X-UI Panel ---${C_RESET}"
    echo -e "\n${C_CYAN}Select which panel to install:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-45s %s\n" "🚀 3X-UI Panel (MHSanaei)" "${C_STATUS_A}⭐ Default${C_RESET}"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-45s %s\n" "📦 X-UI Panel (alireza0)" ""
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ❌ Cancel"
    echo
    read -p "👉 Select panel [1]: " panel_choice
    panel_choice=${panel_choice:-1}
    case $panel_choice in
        1) install_3xui_panel ;;
        2) install_xui_panel ;;
        0) echo -e "\n${C_YELLOW}❌ Installation cancelled.${C_RESET}" ;;
        *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" ;;
    esac
}

install_3xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Install 3X-UI Panel ---${C_RESET}"
    echo -e "\nThis will download and run the official installation script for 3X-UI (MHSanaei)."
    echo -e "Choose an installation option:\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} %-40s\n" "Install the latest version of 3X-UI"
    printf "  ${C_GREEN}[ 2]${C_RESET} %-40s\n" "Install a specific version of 3X-UI"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ❌ Cancel Installation"
    echo
    read -p "👉 Select an option: " choice
    case $choice in
        1)
            echo -e "\n${C_BLUE}⚙️ Installing the latest version...${C_RESET}"
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            ;;
        2)
            read -p "👉 Enter the version to install (e.g., 2.4.5): " version
            if [[ -z "$version" ]]; then
                echo -e "\n${C_RED}❌ Version number cannot be empty.${C_RESET}"
                return
            fi
            echo -e "\n${C_BLUE}⚙️ Installing version ${C_YELLOW}$version...${C_RESET}"
            bash <(curl -Ls "https://raw.githubusercontent.com/mhsanaei/3x-ui/v$version/install.sh") "v$version"
            ;;
        0)
            echo -e "\n${C_YELLOW}❌ Installation cancelled.${C_RESET}"
            ;;
        *)
            echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"
            ;;
    esac
}

install_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📦 Install X-UI Panel (Legacy) ---${C_RESET}"
    echo -e "\nThis will download and run the installation script for X-UI (alireza0)."
    echo -e "Choose an installation option:\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} %-40s\n" "Install the latest version of X-UI"
    printf "  ${C_GREEN}[ 2]${C_RESET} %-40s\n" "Install a specific version of X-UI"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ❌ Cancel Installation"
    echo
    read -p "👉 Select an option: " choice
    case $choice in
        1)
            echo -e "\n${C_BLUE}⚙️ Installing the latest version...${C_RESET}"
            bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
            ;;
        2)
            read -p "👉 Enter the version to install (e.g., 1.8.0): " version
            if [[ -z "$version" ]]; then
                echo -e "\n${C_RED}❌ Version number cannot be empty.${C_RESET}"
                return
            fi
            echo -e "\n${C_BLUE}⚙️ Installing version ${C_YELLOW}$version...${C_RESET}"
            VERSION=$version bash <(curl -Ls "https://raw.githubusercontent.com/alireza0/x-ui/$version/install.sh") "$version"
            ;;
        0)
            echo -e "\n${C_YELLOW}❌ Installation cancelled.${C_RESET}"
            ;;
        *)
            echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"
            ;;
    esac
}

uninstall_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Uninstall X-UI / 3X-UI Panel ---${C_RESET}"
    if ! command -v x-ui &> /dev/null; then
        echo -e "\n${C_YELLOW}ℹ️ No X-UI/3X-UI panel appears to be installed.${C_RESET}"
        return
    fi
    read -p "👉 Are you sure you want to thoroughly uninstall X-UI/3X-UI? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        echo -e "\n${C_BLUE}⚙️ Running the default uninstaller first...${C_RESET}"
        x-ui uninstall >/dev/null 2>&1
        echo -e "\n${C_BLUE}🧹 Performing a full cleanup to ensure complete removal...${C_RESET}"
        echo " - Stopping and disabling x-ui service..."
        systemctl stop x-ui >/dev/null 2>&1
        systemctl disable x-ui >/dev/null 2>&1
        echo " - Removing x-ui files and directories..."
        rm -f /etc/systemd/system/x-ui.service
        rm -f /usr/local/bin/x-ui
        rm -rf /usr/local/x-ui/
        rm -rf /etc/x-ui/
        echo " - Reloading systemd daemon..."
        systemctl daemon-reload
        echo -e "\n${C_GREEN}✅ X-UI/3X-UI has been thoroughly uninstalled.${C_RESET}"
    else
        echo -e "\n${C_YELLOW}❌ Uninstallation cancelled.${C_RESET}"
    fi
}

refresh_ssh_session_cache() {
    local now db_mtime
    printf -v now '%(%s)T' -1
    db_mtime=$(stat -c %Y "$DB_FILE" 2>/dev/null || echo 0)

    if (( SSH_SESSION_CACHE_TS > 0 && now - SSH_SESSION_CACHE_TS < SSH_SESSION_CACHE_TTL && db_mtime == SSH_SESSION_CACHE_DB_MTIME )); then
        return
    fi

    SSH_SESSION_COUNTS=()
    SSH_SESSION_PIDS=()
    SSH_SESSION_TOTAL=0
    SSH_SESSION_CACHE_DB_MTIME=$db_mtime

    if [[ ! -s "$DB_FILE" ]]; then
        SSH_SESSION_CACHE_TS=$now
        return
    fi

    local -A managed_user_lookup=()
    local -A uid_user_lookup=()
    local -A session_pids=()
    local -A loginuid_pids=()
    local managed_user system_user system_uid ssh_pid ssh_owner candidate_user login_uid

    while IFS=: read -r managed_user _rest; do
        [[ -n "$managed_user" && "$managed_user" != \#* ]] && managed_user_lookup["$managed_user"]=1
    done < "$DB_FILE"

    while IFS=: read -r system_user _ system_uid _rest; do
        [[ -n "$system_user" && "$system_uid" =~ ^[0-9]+$ ]] && uid_user_lookup["$system_uid"]="$system_user"
    done < /etc/passwd

    while read -r ssh_pid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue

        # Method 1: process owner matches a managed user directly
        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" && -n "${managed_user_lookup[$ssh_owner]+x}" ]]; then
            session_pids["$ssh_owner"]+="$ssh_pid "
        fi
    done < <(ps -C sshd,sshd-session -o pid=,user= 2>/dev/null)

    # Method 2: kernel loginuid with comm/PPid validation (more robust — matches limiter logic)
    local p pid_dir pid_num comm ppid_val session_user
    for p in /proc/[0-9]*/loginuid; do
        [[ -f "$p" ]] || continue
        login_uid=""
        read -r login_uid < "$p" || login_uid=""
        [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]] || continue

        candidate_user="${uid_user_lookup[$login_uid]}"
        [[ -n "$candidate_user" && -n "${managed_user_lookup[$candidate_user]+x}" ]] || continue

        pid_dir=$(dirname "$p")
        pid_num=$(basename "$pid_dir")
        comm=""
        read -r comm < "$pid_dir/comm" 2>/dev/null || comm=""
        [[ "$comm" == "sshd" || "$comm" == "sshd-session" ]] || continue

        # Filter out the master sshd process (PPid=1)
        ppid_val=""
        while read -r key value; do
            [[ "$key" == "PPid:" ]] && { ppid_val="$value"; break; }
        done < "$pid_dir/status" 2>/dev/null
        [[ "$ppid_val" == "1" ]] && continue

        loginuid_pids["$candidate_user"]+="$pid_num "
    done

    local user pid
    for user in "${!managed_user_lookup[@]}"; do
        # CRITICAL: unset before declare to reset per-user (bash declare is function-scoped)
        unset unique_pids
        local -A unique_pids=()

        # Use ONLY ps-based session_pids for accurate counting.
        # loginuid_pids can double-count (root-owned sshd has user's loginuid on Ubuntu 24)
        for pid in ${session_pids[$user]}; do
            [[ "$pid" =~ ^[0-9]+$ ]] && unique_pids["$pid"]=1
        done

        SSH_SESSION_COUNTS["$user"]=${#unique_pids[@]}
        if (( ${#unique_pids[@]} > 0 )); then
            for pid in "${!unique_pids[@]}"; do
                SSH_SESSION_PIDS["$user"]+="$pid "
            done
            SSH_SESSION_TOTAL=$((SSH_SESSION_TOTAL + ${#unique_pids[@]}))
        fi
    done

    SSH_SESSION_CACHE_TS=$now
}

count_managed_online_sessions() {
    refresh_ssh_session_cache
    echo "$SSH_SESSION_TOTAL"
}

invalidate_banner_cache() {
    BANNER_CACHE_TS=0
    SSH_SESSION_CACHE_TS=0
}

refresh_banner_cache() {
    local now
    printf -v now '%(%s)T' -1
    if (( BANNER_CACHE_TS > 0 && now - BANNER_CACHE_TS < BANNER_CACHE_TTL )); then
        return
    fi

    if [[ -z "$BANNER_CACHE_OS_NAME" ]]; then
        BANNER_CACHE_OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux")
    fi
    BANNER_CACHE_UP_TIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    BANNER_CACHE_RAM_USAGE=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0.00"}}')
    BANNER_CACHE_CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    if [[ -s "$DB_FILE" ]]; then
        BANNER_CACHE_TOTAL_USERS=0
        while IFS=: read -r _u _rest; do
            [[ -n "$_u" && "$_u" != \#* ]] && (( BANNER_CACHE_TOTAL_USERS++ ))
        done < "$DB_FILE"
    else
        BANNER_CACHE_TOTAL_USERS=0
    fi
    BANNER_CACHE_ONLINE_USERS=$(count_managed_online_sessions)
    BANNER_CACHE_TS=$now
}

show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear
    echo
    echo -e "${C_TITLE}   visibleTech Manager ${C_RESET}${C_DIM}| v4.0.0 Premium Edition${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "OS" "$BANNER_CACHE_OS_NAME" "Uptime: $BANNER_CACHE_UP_TIME"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% Used" "Online Sessions: ${C_WHITE}${BANNER_CACHE_ONLINE_USERS}${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Users" "${BANNER_CACHE_TOTAL_USERS} Managed Accounts" "Sys Load (1m): ${C_GREEN}${BANNER_CACHE_CPU_LOAD}${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
}

protocol_menu() {
    while true; do
        show_banner
        local badvpn_status; if systemctl is-active --quiet badvpn; then badvpn_status="${C_STATUS_A}(Active)${C_RESET}"; else badvpn_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        local udp_custom_status; if systemctl is-active --quiet udp-custom; then udp_custom_status="${C_STATUS_A}(Active)${C_RESET}"; else udp_custom_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        local zivpn_status; if systemctl is-active --quiet zivpn.service; then zivpn_status="${C_STATUS_A}(Active)${C_RESET}"; else zivpn_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        
        local ws_status="${C_STATUS_I}(Inactive)${C_RESET}"
        if systemctl is-active --quiet "$WS_SERVICE_NAME"; then
            ws_status="${C_STATUS_A}(Active - $(_cfg_get "$WS_CONFIG_FILE" WS_PORTS))${C_RESET}"
        fi

        local stunnel_status="${C_STATUS_I}(Inactive)${C_RESET}"
        if systemctl is-active --quiet "$STUNNEL_SERVICE_NAME"; then
            stunnel_status="${C_STATUS_A}(Active - $(_cfg_get "$STUNNEL_INFO_FILE" ST_PORT))${C_RESET}"
        fi

        local dnstt_status; if systemctl is-active --quiet server-sldns; then dnstt_status="${C_STATUS_A}(Active)${C_RESET}"; else dnstt_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        
        local v2_status="${C_STATUS_I}(Inactive)${C_RESET}"; if systemctl is-active --quiet ff-xray; then v2_status="${C_STATUS_A}(Active)${C_RESET}"; fi

        local xui_status; if command -v x-ui &> /dev/null; then xui_status="${C_STATUS_A}(Installed)${C_RESET}"; else xui_status="${C_STATUS_I}(Not Installed)${C_RESET}"; fi  # 3X-UI uses same 'x-ui' binary name
        
        echo -e "\n   ${C_TITLE}══════════════[ ${C_BOLD}🔌 PROTOCOL & PANEL MANAGEMENT ${C_RESET}${C_TITLE}]══════════════${C_RESET}"
        echo -e "     ${C_ACCENT}--- TUNNELLING PROTOCOLS---${C_RESET}"
        printf "     ${C_CHOICE}[ 1]${C_RESET} %-45s %s\n" "🚀 Install badvpn (UDP 7300)" "$badvpn_status"
        printf "     ${C_CHOICE}[ 2]${C_RESET} %-45s\n" "🗑️ Uninstall badvpn"
        printf "     ${C_CHOICE}[ 3]${C_RESET} %-45s %s\n" "🚀 Install udp-custom" "$udp_custom_status"
        printf "     ${C_CHOICE}[ 4]${C_RESET} %-45s\n" "🗑️ Uninstall udp-custom"
        printf "     ${C_CHOICE}[ 5]${C_RESET} %-45s %s\n" "🌐 Install WebSocket Proxy (HTTP -> SSH)" "$ws_status"
        printf "     ${C_CHOICE}[ 6]${C_RESET} %-45s\n" "🗑️ Uninstall WebSocket Proxy"
        printf "     ${C_CHOICE}[ 7]${C_RESET} %-45s %s\n" "📡 Install/Manage DNSTT Moded (Port 53)" "$dnstt_status"
        printf "     ${C_CHOICE}[ 8]${C_RESET} %-45s\n" "🗑️ Uninstall DNSTT"
        printf "     ${C_CHOICE}[ 9]${C_RESET} %-45s %s\n" "🔒 Install Stunnel (SSL/TLS)" "$stunnel_status"
        printf "     ${C_CHOICE}[10]${C_RESET} %-45s\n" "🗑️ Uninstall Stunnel"
        printf "     ${C_CHOICE}[11]${C_RESET} %-45s\n" "⚙️ Manage WebSocket & Stunnel (restart/logs)"
        printf "     ${C_CHOICE}[14]${C_RESET} %-45s %s\n" "🛡️ Install ZiVPN (UDP 5667)" "$zivpn_status"
        printf "     ${C_CHOICE}[15]${C_RESET} %-45s\n" "🗑️ Uninstall ZiVPN"
        printf "     ${C_CHOICE}[16]${C_RESET} %-45s %s\n" "🛰️ Install/Manage V2Ray (VMess/VLESS/Trojan)" "$v2_status"
        printf "     ${C_CHOICE}[17]${C_RESET} %-45s\n" "🗑️ Uninstall V2Ray (Xray)"
        
        echo -e "     ${C_ACCENT}--- 💻 MANAGEMENT PANELS ---${C_RESET}"
        printf "     ${C_CHOICE}[12]${C_RESET} %-45s %s\n" "💻 Install X-UI / 3X-UI Panel" "$xui_status"
        printf "     ${C_CHOICE}[13]${C_RESET} %-45s\n" "🗑️ Uninstall X-UI / 3X-UI Panel"
        
        echo -e "   ${C_DIM}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${C_RESET}"
        echo -e "     ${C_WARN}[ 0]${C_RESET} ↩️ Return"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            return
        fi
        case $choice in
            1) install_badvpn; press_enter ;; 2) uninstall_badvpn; press_enter ;;
            3) install_udp_custom; press_enter ;; 4) uninstall_udp_custom; press_enter ;;
            5) install_websocket; press_enter ;; 6) uninstall_websocket; press_enter ;;
            7) install_dnstt; press_enter ;; 8) uninstall_dnstt; press_enter ;;
            9) install_stunnel; press_enter ;; 10) uninstall_stunnel; press_enter ;;
            11) ws_stunnel_menu ;;
            12) install_panel_menu; press_enter ;; 13) uninstall_xui_panel; press_enter ;;
            14) install_zivpn; press_enter ;; 15) uninstall_zivpn; press_enter ;;
            16) install_v2ray; press_enter ;; 17) uninstall_v2ray; press_enter ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}


# ====================================================================
# --- Web Control Panel Functions ---
# ====================================================================

install_web_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Installing Web Control Panel ---${C_RESET}"
    
    if [ -f "$PANEL_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ Web Panel is already installed.${C_RESET}"
        show_panel_credentials
        return
    fi
    
    # Check Python 3
    if ! command -v python3 &>/dev/null; then
        echo -e "${C_RED}❌ Python 3 is required but not installed.${C_RESET}"
        echo -e "${C_YELLOW}Installing python3...${C_RESET}"
        ff_pkg_install python3 || { echo -e "${C_RED}❌ Failed to install python3.${C_RESET}"; return; }
    fi
    
    echo -e "${C_BLUE}🔎 Checking if port $PANEL_PORT is available...${C_RESET}"
    check_and_free_ports "$PANEL_PORT" || return
    check_and_open_firewall_port "$PANEL_PORT" tcp || return
    
    # Generate random credentials and secret URL path
    local panel_user
    panel_user=$(tr -dc 'a-z' < /dev/urandom | head -c 4)$(tr -dc '0-9' < /dev/urandom | head -c 4)
    local panel_pass
    panel_pass=$(tr -dc 'A-Za-z0-9@#$' < /dev/urandom | head -c 16)
    local panel_pass_hash
    panel_pass_hash=$(echo -n "$panel_pass" | sha256sum | awk '{print $1}')
    local panel_secret
    panel_secret="panel_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)"
    
    echo -e "${C_BLUE}📥 Downloading panel files...${C_RESET}"
    mkdir -p "$PANEL_HTML_DIR"
    
    # Download backend
    curl -sL "$PANEL_REPO_BASE/panel.py" -o "$PANEL_SCRIPT"
    if [ $? -ne 0 ] || [ ! -s "$PANEL_SCRIPT" ]; then
        echo -e "${C_RED}❌ Failed to download panel backend.${C_RESET}"
        return
    fi
    chmod +x "$PANEL_SCRIPT"
    sed -i 's/\r$//' "$PANEL_SCRIPT" 2>/dev/null
    
    # Download frontend
    curl -sL "$PANEL_REPO_BASE/index.html" -o "$PANEL_HTML_FILE"
    if [ $? -ne 0 ] || [ ! -s "$PANEL_HTML_FILE" ]; then
        echo -e "${C_RED}❌ Failed to download panel frontend.${C_RESET}"
        return
    fi
    
    # Save credentials
    cat > "$PANEL_CONF" <<-PEOF
PANEL_USER="$panel_user"
PANEL_PASS_HASH="$panel_pass_hash"
PANEL_PASS_PLAIN="$panel_pass"
PANEL_SECRET="$panel_secret"
PEOF
    chmod 600 "$PANEL_CONF"
    
    # Create systemd service
    cat > "$PANEL_SERVICE_FILE" <<-SEOF
[Unit]
Description=visibleTech Web Control Panel
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $PANEL_SCRIPT
Restart=always
RestartSec=5
Nice=10
MemoryHigh=64M
MemoryMax=96M
Environment=PANEL_PORT=$PANEL_PORT

[Install]
WantedBy=multi-user.target
SEOF
    
    systemctl daemon-reload
    systemctl enable visibleTech-panel &>/dev/null
    systemctl start visibleTech-panel &>/dev/null
    sleep 2
    
    if systemctl is-active --quiet visibleTech-panel; then
        local server_ip
        server_ip=$(curl -s -4 --max-time 3 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
        
        clear; show_banner
        echo -e "${C_GREEN}=====================================================${C_RESET}"
        echo -e "${C_GREEN}     ✅ Web Control Panel Installed Successfully!     ${C_RESET}"
        echo -e "${C_GREEN}=====================================================${C_RESET}"
        echo -e "\n${C_CYAN}  🌐 Panel URL:${C_RESET}    ${C_YELLOW}http://${server_ip}:${PANEL_PORT}/${panel_secret}${C_RESET}"
        echo -e "${C_CYAN}  👤 Username:${C_RESET}     ${C_YELLOW}${panel_user}${C_RESET}"
        echo -e "${C_CYAN}  🔑 Password:${C_RESET}     ${C_YELLOW}${panel_pass}${C_RESET}"
        echo -e "${C_CYAN}  🔐 Secret Path:${C_RESET}   ${C_YELLOW}/${panel_secret}${C_RESET}"
        echo -e "\n${C_DIM}  Save these credentials! You can view them later from option [21] > [3].${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Panel service failed to start. Checking logs:${C_RESET}"
        journalctl -u visibleTech-panel -n 15 --no-pager
    fi
}

uninstall_web_panel() {
    if [ ! -f "$PANEL_SERVICE_FILE" ]; then
        if [[ "$UNINSTALL_MODE" != "silent" ]]; then
            echo -e "${C_YELLOW}ℹ️ Web Panel is not installed.${C_RESET}"
        fi
        return
    fi
    
    if [[ "$UNINSTALL_MODE" != "silent" ]]; then
        echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling Web Control Panel ---${C_RESET}"
        read -p "👉 Are you sure you want to uninstall the Web Panel? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            echo -e "\n${C_YELLOW}❌ Uninstallation cancelled.${C_RESET}"
            return
        fi
    fi
    
    echo -e "${C_BLUE}🛑 Stopping and removing Web Panel service...${C_RESET}"
    systemctl stop visibleTech-panel &>/dev/null
    systemctl disable visibleTech-panel &>/dev/null
    rm -f "$PANEL_SERVICE_FILE"
    rm -f "$PANEL_SCRIPT"
    rm -rf "$PANEL_HTML_DIR"
    rm -f "$PANEL_CONF"
    systemctl daemon-reload
    
    echo -e "${C_GREEN}✅ Web Panel has been uninstalled.${C_RESET}"
}

show_panel_credentials() {
    if [ ! -f "$PANEL_CONF" ]; then
        echo -e "\n${C_YELLOW}ℹ️ Web Panel is not installed.${C_RESET}"
        return
    fi
    
    source "$PANEL_CONF"
    local server_ip secret_suffix
    server_ip=$(curl -s -4 --max-time 3 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
    secret_suffix=""
    if [[ -n "$PANEL_SECRET" ]]; then
        secret_suffix="/${PANEL_SECRET}"
    fi
    
    echo -e "\n${C_GREEN}=====================================================${C_RESET}"
    echo -e "${C_GREEN}         🌐 Web Panel Credentials                    ${C_RESET}"
    echo -e "${C_GREEN}=====================================================${C_RESET}"
    echo -e "\n${C_CYAN}  🌐 Panel URL:${C_RESET}    ${C_YELLOW}http://${server_ip}:${PANEL_PORT}${secret_suffix}${C_RESET}"
    echo -e "${C_CYAN}  👤 Username:${C_RESET}     ${C_YELLOW}${PANEL_USER}${C_RESET}"
    echo -e "${C_CYAN}  🔑 Password:${C_RESET}     ${C_YELLOW}${PANEL_PASS_PLAIN}${C_RESET}"
    if [[ -n "$PANEL_SECRET" ]]; then
        echo -e "${C_CYAN}  🔐 Secret Path:${C_RESET}   ${C_YELLOW}/${PANEL_SECRET}${C_RESET}"
    fi
    
    if systemctl is-active --quiet visibleTech-panel 2>/dev/null; then
        echo -e "\n${C_CYAN}  📡 Status:${C_RESET}       ${C_GREEN}🟢 Running${C_RESET}"
    else
        echo -e "\n${C_CYAN}  📡 Status:${C_RESET}       ${C_RED}🔴 Stopped${C_RESET}"
    fi
}

change_panel_credentials() {
    if [ ! -f "$PANEL_CONF" ]; then
        echo -e "\n${C_YELLOW}ℹ️ Web Panel is not installed.${C_RESET}"
        return
    fi
    
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔑 Change Web Panel Credentials & Secret Path ---${C_RESET}"
    show_panel_credentials
    
    echo ""
    read -p "👉 Enter new username (or press Enter to keep current): " new_user
    read -p "🔑 Enter new password (or press Enter to auto-generate): " new_pass
    read -p "🔐 Enter new secret URL path (e.g., secret123, or press Enter to keep): " new_secret
    
    source "$PANEL_CONF"
    
    if [[ -z "$new_user" ]]; then
        new_user="$PANEL_USER"
    fi
    if [[ -z "$new_pass" ]]; then
        new_pass=$(tr -dc 'A-Za-z0-9@#$' < /dev/urandom | head -c 16)
        echo -e "${C_GREEN}🔑 Auto-generated password: ${C_YELLOW}$new_pass${C_RESET}"
    fi
    if [[ -z "$new_secret" ]]; then
        new_secret="${PANEL_SECRET:-panel_$(tr -dc 'a-z0-9' < /dev/urandom | head -c 8)}"
    fi
    new_secret=$(echo "$new_secret" | sed 's/^\///')
    
    local new_hash
    new_hash=$(echo -n "$new_pass" | sha256sum | awk '{print $1}')
    
    cat > "$PANEL_CONF" <<-PEOF
PANEL_USER="$new_user"
PANEL_PASS_HASH="$new_hash"
PANEL_PASS_PLAIN="$new_pass"
PANEL_SECRET="$new_secret"
PEOF
    chmod 600 "$PANEL_CONF"
    
    systemctl restart visibleTech-panel &>/dev/null
    echo -e "\n${C_GREEN}✅ Panel credentials & secret path updated!${C_RESET}"
    echo -e "  ${C_CYAN}👤 Username:${C_RESET}    ${C_YELLOW}$new_user${C_RESET}"
    echo -e "  ${C_CYAN}🔑 Password:${C_RESET}    ${C_YELLOW}$new_pass${C_RESET}"
    echo -e "  ${C_CYAN}🔐 Secret Path:${C_RESET}  ${C_YELLOW}/$new_secret${C_RESET}"
}

web_panel_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Web Control Panel ---${C_RESET}\n"
        
        if [ -f "$PANEL_SERVICE_FILE" ]; then
            if systemctl is-active --quiet visibleTech-panel 2>/dev/null; then
                echo -e "  ${C_DIM}Status: ${C_GREEN}🟢 Installed & Running${C_RESET}\n"
            else
                echo -e "  ${C_DIM}Status: ${C_RED}🔴 Installed but Stopped${C_RESET}\n"
            fi
        else
            echo -e "  ${C_DIM}Status: ${C_YELLOW}⚪ Not Installed${C_RESET}\n"
        fi
        
        printf "  ${C_GREEN}[ 1]${C_RESET} %-35s\n" "🚀 Install Web Panel"
        printf "  ${C_GREEN}[ 2]${C_RESET} %-35s\n" "🗑️  Uninstall Web Panel"
        printf "  ${C_GREEN}[ 3]${C_RESET} %-35s\n" "🔑 Show Panel Credentials"
        printf "  ${C_GREEN}[ 4]${C_RESET} %-35s\n" "🔄 Change Panel Credentials"
        printf "  ${C_GREEN}[ 5]${C_RESET} %-35s\n" "🔃 Restart Panel Service"
        echo -e "\n  ${C_RED}[ 0]${C_RESET} ↩️  Back to Main Menu"
        echo
        
        read -r -p "👉 Enter your choice: " panel_choice
        case $panel_choice in
            1) install_web_panel; press_enter ;;
            2) uninstall_web_panel; press_enter ;;
            3) show_panel_credentials; press_enter ;;
            4) change_panel_credentials; press_enter ;;
            5)
                if [ -f "$PANEL_SERVICE_FILE" ]; then
                    systemctl restart visibleTech-panel &>/dev/null
                    sleep 1
                    if systemctl is-active --quiet visibleTech-panel; then
                        echo -e "\n${C_GREEN}✅ Web Panel service restarted successfully.${C_RESET}"
                    else
                        echo -e "\n${C_RED}❌ Failed to restart. Checking logs:${C_RESET}"
                        journalctl -u visibleTech-panel -n 10 --no-pager
                    fi
                else
                    echo -e "\n${C_YELLOW}ℹ️ Web Panel is not installed.${C_RESET}"
                fi
                press_enter
                ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

uninstall_script() {
    clear; show_banner
    echo -e "${C_RED}=====================================================${C_RESET}"
    echo -e "${C_RED}       🔥 DANGER: UNINSTALL SCRIPT & ALL DATA 🔥      ${C_RESET}"
    echo -e "${C_RED}=====================================================${C_RESET}"
    echo -e "${C_YELLOW}This will PERMANENTLY remove this script and all its components, including:"
    echo -e " - The main command ($(command -v menu))"
    echo -e " - All configuration and user data ($DB_DIR)"
    echo -e " - The active limiter service ($LIMITER_SERVICE)"
    echo -e " - All installed services (badvpn, udp-custom, WebSocket, Stunnel, DNSTT)"
    echo -e "\n${C_RED}This action is irreversible.${C_RESET}"
    echo ""
    read -p "👉 Type 'yes' to confirm and proceed with uninstallation: " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo -e "\n${C_GREEN}✅ Uninstallation cancelled.${C_RESET}"
        return
    fi
    local -a removable_users=()
    local remove_users_confirm
    local remove_users_on_uninstall=false
    mapfile -t removable_users < <(get_visibleTech_known_users)
    if [[ ${#removable_users[@]} -gt 0 ]]; then
        echo -e "\n${C_YELLOW}visibleTech SSH users detected on this VPS:${C_RESET} ${removable_users[*]}"
        read -p "👉 Do you also want to permanently delete these SSH users before uninstalling? (y/n): " remove_users_confirm
        if [[ "$remove_users_confirm" == "y" || "$remove_users_confirm" == "Y" ]]; then
            remove_users_on_uninstall=true
        fi
    fi
    export UNINSTALL_MODE="silent"
    echo -e "\n${C_BLUE}--- 💥 Starting Uninstallation 💥 ---${C_RESET}"
    
    if [[ "$remove_users_on_uninstall" == "true" ]]; then
        echo -e "\n${C_BLUE}🗑️ Removing visibleTech SSH users before uninstall...${C_RESET}"
        delete_visibleTech_user_accounts "${removable_users[@]}"
    fi
    
    echo -e "\n${C_BLUE}🗑️ Removing active limiter service...${C_RESET}"
    systemctl stop visibleTech-limiter &>/dev/null
    systemctl disable visibleTech-limiter &>/dev/null
    rm -f "$LIMITER_SERVICE"
    rm -f "$LIMITER_SCRIPT"
    
    echo -e "\n${C_BLUE}🗑️ Removing bandwidth monitoring service...${C_RESET}"
    systemctl stop visibleTech-bandwidth &>/dev/null
    systemctl disable visibleTech-bandwidth &>/dev/null
    rm -f "$BANDWIDTH_SERVICE"
    rm -f "$BANDWIDTH_SCRIPT"
    rm -rf "$LEGACY_BANDWIDTH_DIR"
    rm -f "$TRIAL_CLEANUP_SCRIPT"
    
    echo -e "\n${C_BLUE}\ud83d\uddd1\ufe0f Removing SSH login banner...${C_RESET}"
    rm -f "$LOGIN_INFO_SCRIPT"
    rm -f "$SSHD_FF_CONFIG"
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
    
    chattr -i /etc/resolv.conf &>/dev/null

    uninstall_dnstt
    uninstall_badvpn
    uninstall_udp_custom
    uninstall_websocket
    uninstall_stunnel
    uninstall_v2ray
    uninstall_zivpn
    uninstall_web_panel
    delete_dns_record
    
    echo -e "\n${C_BLUE}🔄 Reloading systemd daemon...${C_RESET}"
    systemctl daemon-reload
    
    echo -e "\n${C_BLUE}🗑️ Removing script and configuration files...${C_RESET}"
    rm -rf "$BADVPN_BUILD_DIR"
    rm -rf "$UDP_CUSTOM_DIR"
    rm -rf "$DB_DIR"
    rm -f "$(command -v menu)"
    
    echo -e "\n${C_GREEN}=============================================${C_RESET}"
    echo -e "${C_GREEN}      Script has been successfully uninstalled.     ${C_RESET}"
    echo -e "${C_GREEN}=============================================${C_RESET}"
    echo -e "\nAll associated files and services have been removed."
    echo "The 'menu' command will no longer work."
    exit 0
}

# --- NEW FEATURES ---

create_trial_account() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ⏱️ Create Trial/Test Account ---${C_RESET}"
    
    # Ensure 'at' daemon is available
    if ! command -v at &>/dev/null; then
        echo -e "${C_YELLOW}⚠️ 'at' command not found. Installing...${C_RESET}"
        ff_pkg_install at >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to install 'at'. Cannot schedule auto-expiry.${C_RESET}"
            return
        }
        systemctl enable atd &>/dev/null
        systemctl start atd &>/dev/null
    fi
    
    # Ensure atd is running
    if ! systemctl is-active --quiet atd; then
        systemctl start atd &>/dev/null
    fi
    
    echo -e "\n${C_CYAN}Select trial duration:${C_RESET}\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} ⏱️  1 Hour\n"
    printf "  ${C_GREEN}[ 2]${C_RESET} ⏱️  2 Hours\n"
    printf "  ${C_GREEN}[ 3]${C_RESET} ⏱️  3 Hours\n"
    printf "  ${C_GREEN}[ 4]${C_RESET} ⏱️  6 Hours\n"
    printf "  ${C_GREEN}[ 5]${C_RESET} ⏱️  12 Hours\n"
    printf "  ${C_GREEN}[ 6]${C_RESET} 📅  1 Day\n"
    printf "  ${C_GREEN}[ 7]${C_RESET} 📅  3 Days\n"
    printf "  ${C_GREEN}[ 8]${C_RESET} ⚙️  Custom (enter hours)\n"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ↩️ Cancel"
    echo
    read -p "👉 Select duration: " dur_choice
    
    local duration_hours=0
    local duration_label=""
    case $dur_choice in
        1) duration_hours=1;   duration_label="1 Hour" ;;
        2) duration_hours=2;   duration_label="2 Hours" ;;
        3) duration_hours=3;   duration_label="3 Hours" ;;
        4) duration_hours=6;   duration_label="6 Hours" ;;
        5) duration_hours=12;  duration_label="12 Hours" ;;
        6) duration_hours=24;  duration_label="1 Day" ;;
        7) duration_hours=72;  duration_label="3 Days" ;;
        8) read -p "👉 Enter custom duration in hours: " custom_hours
           if ! [[ "$custom_hours" =~ ^[0-9]+$ ]] || [[ "$custom_hours" -lt 1 ]]; then
               echo -e "\n${C_RED}❌ Invalid number of hours.${C_RESET}"; return
           fi
           duration_hours=$custom_hours
           duration_label="$custom_hours Hours"
           ;;
        0) echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; return ;;
        *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"; return ;;
    esac
    
    # Username
    local rand_suffix=$(tr -dc 'a-z0-9' < /dev/urandom | head -c 5)
    local default_username="trial_${rand_suffix}"
    read -p "👤 Username [${default_username}]: " username
    username=${username:-$default_username}
    
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ Error: User '$username' already exists.${C_RESET}"; return
    fi
    
    # Password
    local password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
    read -p "🔑 Password [${password}]: " custom_pass
    password=${custom_pass:-$password}
    
    # Connection limit
    read -p "📶 Connection limit [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    # Bandwidth limit
    read -p "📦 Bandwidth limit in GB (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    # Calculate expiry
    local expire_date
    if [[ "$duration_hours" -ge 24 ]]; then
        local days=$((duration_hours / 24))
        expire_date=$(date -d "+$days days" +%Y-%m-%d)
    else
        # For sub-day durations, set expiry to tomorrow to be safe (at job does the real cleanup)
        expire_date=$(date -d "+1 day" +%Y-%m-%d)
    fi
    local expiry_timestamp
    expiry_timestamp=$(date -d "+${duration_hours} hours" '+%Y-%m-%d %H:%M:%S')
    
    # Create the system user
    ensure_visibleTech_system_group
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb:trial" >> "$DB_FILE"
    
    # Schedule auto-cleanup via 'at'
    echo "$TRIAL_CLEANUP_SCRIPT $username" | at now + ${duration_hours} hours 2>/dev/null
    
    local bw_display="Unlimited"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
    
    clear; show_banner
    echo -e "${C_GREEN}✅ Trial account created successfully!${C_RESET}\n"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "  ⏱️  ${C_BOLD}TRIAL ACCOUNT${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "  - 👤 Username:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Password:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - ⏱️ Duration:          ${C_CYAN}$duration_label${C_RESET}"
    echo -e "  - 🕐 Auto-expires at:   ${C_RED}$expiry_timestamp${C_RESET}"
    echo -e "  - 📶 Connection Limit:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Bandwidth Limit:   ${C_YELLOW}$bw_display${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "\n${C_DIM}The account will be automatically deleted when the trial expires.${C_RESET}"
    
    # Auto-ask for config generation
    echo
    read -p "👉 Generate client config for this trial user? (y/n): " gen_conf
    if [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]]; then
        generate_client_config "$username" "$password"
    fi
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

view_user_bandwidth() {
    _select_user_interface "--- 📊 View User Bandwidth ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then return; fi
    
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📊 Bandwidth Details: ${C_YELLOW}$u${C_PURPLE} ---${C_RESET}\n"
    
    local line; line=$(grep "^$u:" "$DB_FILE")
    local _u _p _e _l bandwidth_gb
    IFS=: read -r _u _p _e _l bandwidth_gb _ <<< "$line"
    [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"
    
    local used_bytes=0
    if [[ -f "$BANDWIDTH_DIR/${u}.usage" ]]; then
        read -r used_bytes < "$BANDWIDTH_DIR/${u}.usage" 2>/dev/null || used_bytes=0
        [[ -z "$used_bytes" ]] && used_bytes=0
    fi
    
    local used_mb; used_mb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1048576}")
    local used_gb; used_gb=$(awk "BEGIN {printf \"%.3f\", $used_bytes / 1073741824}")
    
    echo -e "  ${C_CYAN}Data Used:${C_RESET}        ${C_WHITE}${used_gb} GB${C_RESET} (${used_mb} MB)"
    
    if [[ "$bandwidth_gb" == "0" ]]; then
        echo -e "  ${C_CYAN}Bandwidth Limit:${C_RESET}  ${C_GREEN}Unlimited${C_RESET}"
        echo -e "  ${C_CYAN}Status:${C_RESET}           ${C_GREEN}No quota restrictions${C_RESET}"
    else
        local quota_bytes; quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        local percentage; percentage=$(awk "BEGIN {printf \"%.1f\", ($used_bytes / $quota_bytes) * 100}")
        local remaining_bytes; remaining_bytes=$((quota_bytes - used_bytes))
        if [[ "$remaining_bytes" -lt 0 ]]; then remaining_bytes=0; fi
        local remaining_gb; remaining_gb=$(awk "BEGIN {printf \"%.3f\", $remaining_bytes / 1073741824}")
        
        echo -e "  ${C_CYAN}Bandwidth Limit:${C_RESET}  ${C_YELLOW}${bandwidth_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Remaining:${C_RESET}        ${C_WHITE}${remaining_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Usage:${C_RESET}            ${C_WHITE}${percentage}%${C_RESET}"
        
        # Progress bar
        local bar_width=30
        local filled; filled=$(awk "BEGIN {printf \"%.0f\", ($percentage / 100) * $bar_width}")
        if [[ "$filled" -gt "$bar_width" ]]; then filled=$bar_width; fi
        local empty=$((bar_width - filled))
        local bar_color="$C_GREEN"
        if (( $(awk "BEGIN {print ($percentage > 80)}" ) )); then bar_color="$C_RED"
        elif (( $(awk "BEGIN {print ($percentage > 50)}" ) )); then bar_color="$C_YELLOW"
        fi
        printf "  ${C_CYAN}Progress:${C_RESET}         ${bar_color}["
        for ((i=0; i<filled; i++)); do printf "█"; done
        for ((i=0; i<empty; i++)); do printf "░"; done
        printf "]${C_RESET} ${percentage}%%\n"
        
        if [[ "$used_bytes" -ge "$quota_bytes" ]]; then
            echo -e "\n  ${C_RED}⚠️ USER HAS EXCEEDED BANDWIDTH QUOTA — ACCOUNT LOCKED${C_RESET}"
        fi
    fi
}

bulk_create_users() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👥 Bulk Create Users ---${C_RESET}"
    
    read -p "👉 Enter username prefix (e.g., 'user'): " prefix
    if [[ -z "$prefix" ]]; then echo -e "\n${C_RED}❌ Prefix cannot be empty.${C_RESET}"; return; fi
    
    read -p "🔢 How many users to create? " count
    if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 100 ]]; then
        echo -e "\n${C_RED}❌ Invalid count (1-100).${C_RESET}"; return
    fi
    
    read -p "🗓️ Account duration (in days) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    read -p "📶 Connection limit per user [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    read -p "📦 Bandwidth limit in GB per user (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    read -p "📦 DAILY bandwidth limit in GB per user (0 = unlimited) [0]: " daily_bandwidth_gb
    daily_bandwidth_gb=${daily_bandwidth_gb:-0}
    if ! [[ "$daily_bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    local expire_date
    expire_date=$(date -d "+$days days" +%Y-%m-%d)
    local bw_display="Unlimited"; [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"
    local daily_bw_display="Unlimited"; [[ "$daily_bandwidth_gb" != "0" ]] && daily_bw_display="${daily_bandwidth_gb} GB/day"
    ensure_visibleTech_system_group
    
    echo -e "\n${C_BLUE}⚙️ Creating $count users with prefix '${prefix}'...${C_RESET}\n"
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-20s | %-15s | %-12s${C_RESET}\n" "USERNAME" "PASSWORD" "EXPIRES"
    echo -e "${C_YELLOW}----------------------------------------------------------------${C_RESET}"
    
    local created=0
    for ((i=1; i<=count; i++)); do
        local username="${prefix}${i}"
        if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
            echo -e "${C_RED}  ⚠️ Skipping '$username' — already exists${C_RESET}"
            continue
        fi
        local password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 8)
        useradd -m -s /usr/sbin/nologin "$username"
        usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
        echo "$username:$password" | chpasswd
        chage -E "$expire_date" "$username"
        echo "$username:$password:$expire_date:$limit:$bandwidth_gb:$daily_bandwidth_gb:bulk" >> "$DB_FILE"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        created=$((created + 1))
    done
    
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    echo -e "\n${C_GREEN}✅ Created $created users. Conn Limit: ${limit} | Total BW: ${bw_display} | Daily BW: ${daily_bw_display}${C_RESET}"
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

generate_client_config() {
    local user=$1
    local pass=$2
    
    local host_ip=$(curl -s -4 icanhazip.com)
    local host_domain
    host_domain=$(detect_preferred_host)
    [[ -z "$host_domain" ]] && host_domain="$host_ip"

    echo -e "\n${C_BOLD}${C_PURPLE}--- 📱 Client Connection Configuration ---${C_RESET}"
    echo -e "${C_CYAN}Copy the details below to your clipboard:${C_RESET}\n"

    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "👤 ${C_BOLD}User Details${C_RESET}"
    echo -e "   • Username: ${C_WHITE}$user${C_RESET}"
    echo -e "   • Password: ${C_WHITE}$pass${C_RESET}"
    echo -e "   • Host/IP : ${C_WHITE}$host_domain${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    
    # 1. SSH Direct
    echo -e "\n🔹 ${C_BOLD}SSH Direct${C_RESET}:"
    echo -e "   • Host: $host_domain"
    echo -e "   • Port: 22"
    echo -e "   • payload: (Standard SSH)"

    # 2. WebSocket / Stunnel
    print_tunnel_endpoints "$host_domain"

    # 3. UDP Custom
    if systemctl is-active --quiet udp-custom; then
        echo -e "\n🔹 ${C_BOLD}UDP Custom${C_RESET}:"
        echo -e "   • IP: $host_ip (Must use numeric IP)"
        echo -e "   • Port: 1-65535 (Exclude 53, 5300)"
        echo -e "   • Obfs: (None/Plain)"
    fi

    # 4. DNSTT (FastDns Moded)
    if systemctl is-active --quiet server-sldns; then
        echo -e "\n🔹 ${C_BOLD}DNSTT (FastDns)${C_RESET}:"
        echo -e "   • Nameserver: $(fastdns_main_domain)"
        local _xd
        while read -r _xd; do
            [[ -n "$_xd" ]] && echo -e "   • Extra Nameserver: $_xd"
        done < <(fastdns_extra_domains)
        echo -e "   • PubKey: $(fastdns_pubkey)"
        echo -e "   • DNS IP: 1.1.1.1 / 8.8.8.8"
    fi
    
    # 4b. V2Ray (Xray)
    if systemctl is-active --quiet ff-xray; then
        echo -e "\n🔹 ${C_BOLD}V2Ray (Xray: VMess / VLESS / Trojan)${C_RESET}:"
        echo -e "   • Domain: $(v2 get domain)"
        echo -e "   • TLS port: $(v2 get tls_port) (WS + gRPC)   Non-TLS port: $(v2 get http_port) (WS)"
        echo -e "   • Paths: /vmess  /vless  /trojan-ws   gRPC: vmess-grpc  vless-grpc  trojan-grpc"
        echo -e "   • Links per account: Main Menu > V2Ray (Xray) Manager"
    fi

    # 5. ZiVPN
    if systemctl is-active --quiet zivpn; then
        echo -e "\n🔹 ${C_BOLD}ZiVPN${C_RESET}:"
        echo -e "   • UDP Port: 5667"
        echo -e "   • Forwarded Ports: 6000-19999"
    fi
    
    echo -e "${C_YELLOW}========================================${C_RESET}"

}

client_config_menu() {
    _select_user_interface "--- 📱 Generate Client Config ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then return; fi
    
    # We need to find the password. It's in the DB.
    local pass=$(grep "^$u:" "$DB_FILE" | cut -d: -f2)
    generate_client_config "$u" "$pass"
}

format_rate_from_kbps() {
    local kbps=${1:-0}
    if (( kbps >= 1024 )); then
        printf "%d.%02d MB/s" $((kbps / 1024)) $((((kbps % 1024) * 100) / 1024))
    else
        printf "%d KB/s" "$kbps"
    fi
}

# Lightweight Bash Monitor (No vnStat required)
simple_live_monitor() {
    local iface=$1
    local rx_file="/sys/class/net/$iface/statistics/rx_bytes"
    local tx_file="/sys/class/net/$iface/statistics/tx_bytes"
    local interval=2
    local stop_monitor=0
    local rx1 tx1 rx2 tx2 rx_diff tx_diff rx_kbs tx_kbs rx_fmt tx_fmt

    if [[ -z "$iface" || ! -r "$rx_file" || ! -r "$tx_file" ]]; then
        echo -e "\n${C_RED}❌ Could not read interface statistics for '${iface:-unknown}'.${C_RESET}"
        return
    fi

    echo -e "\n${C_BLUE}⚡ Starting Lightweight Traffic Monitor for $iface...${C_RESET}"
    echo -e "${C_DIM}Press [Ctrl+C] to stop.${C_RESET}\n"

    read -r rx1 < "$rx_file"
    read -r tx1 < "$tx_file"

    printf "%-15s | %-15s\n" "⬇️ Download" "⬆️ Upload"
    echo "-----------------------------------"

    trap 'stop_monitor=1' INT TERM
    while (( ! stop_monitor )); do
        sleep "$interval"
        read -r rx2 < "$rx_file" || break
        read -r tx2 < "$tx_file" || break

        rx_diff=$((rx2 - rx1))
        tx_diff=$((tx2 - tx1))
        (( rx_diff < 0 )) && rx_diff=0
        (( tx_diff < 0 )) && tx_diff=0

        rx_kbs=$((rx_diff / 1024 / interval))
        tx_kbs=$((tx_diff / 1024 / interval))
        rx_fmt=$(format_rate_from_kbps "$rx_kbs")
        tx_fmt=$(format_rate_from_kbps "$tx_kbs")

        printf "\r%-15s | %-15s" "$rx_fmt" "$tx_fmt"

        rx1=$rx2
        tx1=$tx2
    done
    trap - INT TERM
    echo
}

traffic_monitor_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📈 Network Traffic Monitor ---${C_RESET}"
    
    # Find active interface
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    
    echo -e "\nInterface: ${C_CYAN}${iface}${C_RESET}"
    
    echo -e "\n${C_BOLD}Select a monitoring option:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "⚡ Live Monitor ${C_DIM}(Lightweight, No Install)${C_RESET}"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "📊 View Total Traffic Since Boot"
    printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "📅 Daily/Monthly Logs ${C_DIM}(Requires vnStat)${C_RESET}"
    
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
    echo
    read -p "👉 Enter choice: " t_choice
    case $t_choice in
        1) 
           simple_live_monitor "$iface"
           ;;
        2)
            local rx_total=$(cat /sys/class/net/$iface/statistics/rx_bytes)
            local tx_total=$(cat /sys/class/net/$iface/statistics/tx_bytes)
            local rx_mb=$((rx_total / 1024 / 1024))
            local tx_mb=$((tx_total / 1024 / 1024))
            echo -e "\n${C_BLUE}📊 Total Traffic (Since Boot):${C_RESET}"
            echo -e "   ⬇️ Download: ${C_WHITE}${rx_mb} MB${C_RESET}"
            echo -e "   ⬆️ Upload:   ${C_WHITE}${tx_mb} MB${C_RESET}"
            press_enter
            ;;
        3) 
           # vnStat Logic
           if ! command -v vnstat &> /dev/null; then
               echo -e "\n${C_YELLOW}⚠️ vnStat is not installed.${C_RESET}"
               echo -e "   This tool provides persistent history (Daily/Monthly reports)."
               echo -e "   It is lightweight but requires installation."
               read -p "👉 Install vnStat now? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                     echo -e "\n${C_BLUE}📦 Installing vnStat...${C_RESET}"
                     ff_pkg_install vnstat >/dev/null 2>&1 || {
                         echo -e "${C_RED}❌ Failed to install vnStat.${C_RESET}"
                         sleep 1
                         return
                     }
                     systemctl enable vnstat >/dev/null 2>&1
                     systemctl restart vnstat >/dev/null 2>&1
                    local default_iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
                    vnstat --add -i "$default_iface" >/dev/null 2>&1
                    echo -e "${C_GREEN}✅ Installed.${C_RESET}"
                    sleep 1
               else
                    return
               fi
           fi
           echo
           vnstat -i "$iface"
           echo -e "\n${C_DIM}Run 'vnstat -d' or 'vnstat -m' manually for specific views.${C_RESET}"
           press_enter
           ;;
        *) return ;;
    esac
}

torrent_block_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚫 Torrent Blocking (Anti-Torrent) ---${C_RESET}"
    
    # Check status
    local torrent_status="${C_STATUS_I}Disabled${C_RESET}"
    if iptables -L FORWARD | grep -q "ipp2p"; then
         torrent_status="${C_STATUS_A}Enabled${C_RESET}"
    elif iptables -L OUTPUT | grep -q "BitTorrent"; then
         # Fallback check for string matching
         torrent_status="${C_STATUS_A}Enabled${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Current Status: ${torrent_status}${C_RESET}"
    echo -e "${C_DIM}This feature uses iptables string matching to block common torrent keywords.${C_RESET}"
    
    echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🔒 Enable Torrent Blocking"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "🔓 Disable Torrent Blocking"
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
    echo
    read -p "👉 Enter choice: " b_choice
    
    case $b_choice in
        1)
            echo -e "\n${C_BLUE}🛡️ Applying Anti-Torrent rules...${C_RESET}"
            # Clean old rules first to avoid duplicates
            _flush_torrent_rules
            
            # Block Common Torrent Ports/Keywords
            # String matching using iptables extension
            iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP
            iptables -A FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP
            iptables -A FORWARD -m string --string "peer_id=" --algo bm -j DROP
            iptables -A FORWARD -m string --string ".torrent" --algo bm -j DROP
            iptables -A FORWARD -m string --string "announce.php?passkey=" --algo bm -j DROP
            iptables -A FORWARD -m string --string "torrent" --algo bm -j DROP
            iptables -A FORWARD -m string --string "info_hash" --algo bm -j DROP
            iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
            iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
            
            # Same for OUTPUT to be safe
            iptables -A OUTPUT -m string --string "BitTorrent" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "peer_id=" --algo bm -j DROP
            iptables -A OUTPUT -m string --string ".torrent" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "announce.php?passkey=" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "torrent" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "info_hash" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "get_peers" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "find_node" --algo bm -j DROP
            
            # Attempt to save if iptables-persistent exists
            if ff_pkg_is_installed iptables-persistent &>/dev/null; then
                netfilter-persistent save &>/dev/null
            fi
            
            echo -e "${C_GREEN}✅ Torrent Blocking Enabled.${C_RESET}"
            press_enter
            ;;
        2)
            echo -e "\n${C_BLUE}🔓 Removing Anti-Torrent rules...${C_RESET}"
            _flush_torrent_rules
            if ff_pkg_is_installed iptables-persistent &>/dev/null; then
                netfilter-persistent save &>/dev/null
            fi
            echo -e "${C_GREEN}✅ Torrent Blocking Disabled.${C_RESET}"
            press_enter
            ;;
        *) return ;;
    esac
}

_flush_torrent_rules() {
    # Helper to remove rules containing specific strings
    # This is a bit brute-force but effective for this script's scope
    iptables -D FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "announce.php?passkey=" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "torrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "find_node" --algo bm -j DROP 2>/dev/null

    iptables -D OUTPUT -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "announce.php?passkey=" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "torrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "find_node" --algo bm -j DROP 2>/dev/null
}

ssh_banner_menu() {
    while true; do
        show_banner
        local banner_mode
        local banner_status
        banner_mode=$(get_ssh_banner_mode)
        case "$banner_mode" in
            dynamic) banner_status="${C_STATUS_A}Dynamic${C_RESET}" ;;
            static) banner_status="${C_STATUS_A}Static${C_RESET}" ;;
            *) banner_status="${C_STATUS_I}Disabled${C_RESET}" ;;
        esac

        echo -e "\n   ${C_TITLE}═════════════════[ ${C_BOLD}🎨 SSH BANNER MODE: ${banner_status} ${C_RESET}${C_TITLE}]═════════════════${C_RESET}"
        echo -e "${C_DIM}Static mode uses 'Banner $SSH_BANNER_FILE'. Dynamic mode shows per-user account info.${C_RESET}"
        printf "     ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "✨ Enable Dynamic Account Banner"
        printf "     ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "📋 Paste or Replace Static Banner"
        printf "     ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "👁️ View Current Static Banner"
        printf "     ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "📝 Preview Dynamic Banner"
        printf "     ${C_DANGER}[ 5]${C_RESET} %-40s\n" "🗑️ Disable All SSH Banners"
        echo -e "   ${C_DIM}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${C_RESET}"
        echo -e "     ${C_WARN}[ 0]${C_RESET} ↩️ Return"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            return
        fi
        case $choice in
            1)
                if setup_ssh_login_info; then
                    echo -e "\n${C_GREEN}✅ Dynamic account banner enabled.${C_RESET}"
                    echo -e "${C_DIM}Users will now see their account info banner instead of the static banner.${C_RESET}"
                fi
                press_enter
                ;;
            2) set_ssh_banner_paste ;;
            3) view_ssh_banner ;;
            4) preview_dynamic_ssh_banner ;;
            5) remove_ssh_banner ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" && sleep 1 ;;
        esac
    done
}

auto_reboot_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔄 Auto-Reboot Management ---${C_RESET}"
    
    # Check status
    local cron_check=$(crontab -l 2>/dev/null | grep "systemctl reboot")
    local status="${C_STATUS_I}Disabled${C_RESET}"
    if [[ -n "$cron_check" ]]; then
        status="${C_STATUS_A}Active (Midnight)${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Current Status: ${status}${C_RESET}"
    
    echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🕐 Enable Daily Reboot (00:00 midnight)"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "❌ Disable Auto-Reboot"
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
    echo
    read -p "👉 Enter choice: " r_choice
    
    case $r_choice in
        1)
            # Remove existing to prevent duplicates
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab -
            # Add new job
            (crontab -l 2>/dev/null; echo "0 0 * * * systemctl reboot") | crontab -
            echo -e "\n${C_GREEN}✅ Auto-reboot scheduled for every day at 00:00.${C_RESET}"
            press_enter
            ;;
        2)
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab -
            echo -e "\n${C_GREEN}✅ Auto-reboot disabled.${C_RESET}"
            press_enter
            ;;
        *) return ;;
    esac
}


press_enter() {
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return to the menu..." && read -r || true
}
invalid_option() {
    echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" && sleep 1
}

main_menu() {
    while true; do
        export UNINSTALL_MODE="interactive"
        show_banner
        
        echo
        echo -e "   ${C_TITLE}═══════════════════[ ${C_BOLD}👤 USER MANAGEMENT ${C_RESET}${C_TITLE}]═══════════════════${C_RESET}"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "1" "✨ Create New User" "2" "🗑️  Delete User"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "3" "🔄 Renew User Account" "4" "🔒 Lock User Account"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "5" "🔓 Unlock User Account" "6" "✏️  Edit User Details"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "7" "📋 List Managed Users" "8" "📱 Generate Client Config"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "9" "⏱️  Create Trial Account" "10" "📊 View User Bandwidth"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "11" "👥 Bulk Create Users"
        
        echo
        echo -e "   ${C_TITLE}══════════════[ ${C_BOLD}🌐 VPN & PROTOCOLS ${C_RESET}${C_TITLE}]═══════════════${C_RESET}"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "12" "🔌 Protocol Manager" "13" "📈 Traffic Monitor (Lite)"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "14" "🚫 Block Torrent (Anti-P2P)"
        echo
        echo -e "   ${C_TITLE}══════════════[ ${C_BOLD}⚙️ SYSTEM SETTINGS ${C_RESET}${C_TITLE}]═══════════════${C_RESET}"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "15" "🌐 Free Domain (deSEC)" "16" "🎨 SSH Banner Config"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "17" "🔄 Auto-Reboot Task" "18" "💾 Backup User Data"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "19" "📥 Restore User Data" "20" "🧹 Cleanup Expired Users"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "21" "🌐 Web Control panel"
        printf "     ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "22" "🛰️  V2Ray (Xray) Manager"

        echo
        echo -e "   ${C_DANGER}═══════════════════[ ${C_BOLD}🔥 DANGER ZONE ${C_RESET}${C_DANGER}]═══════════════════${C_RESET}"
        echo -e "     ${C_DANGER}[99]${C_RESET} Uninstall Script             ${C_WARN}[ 0]${C_RESET} Exit"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            exit 0
        fi
        case $choice in
            1) create_user; press_enter ;;
            2) delete_user; press_enter ;;
            3) renew_user; press_enter ;;
            4) lock_user; press_enter ;;
            5) unlock_user; press_enter ;;
            6) edit_user; press_enter ;;
            7) list_users; press_enter ;;
            8) client_config_menu; press_enter ;;
            9) create_trial_account; press_enter ;;
            10) view_user_bandwidth; press_enter ;;
            11) bulk_create_users; press_enter ;;
            
            12) protocol_menu ;;
            13) traffic_monitor_menu ;;
            14) torrent_block_menu ;;
            
            15) dns_menu; press_enter ;;
            16) ssh_banner_menu ;;
            17) auto_reboot_menu ;;
            18) backup_user_data; press_enter ;;
            19) restore_user_data; press_enter ;;
            20) cleanup_expired; press_enter ;;
            21) web_panel_menu ;;
            22) v2ray_entry ;;
            
            99) uninstall_script ;;
            0) exit 0 ;;
            *) invalid_option ;;
        esac
    done
}

if [[ "$1" == "--install-setup" ]]; then
    initial_setup
    exit 0
fi

require_interactive_terminal
sync_runtime_components_if_needed
main_menu
