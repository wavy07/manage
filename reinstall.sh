#!/usr/bin/env bash
# =============================================================================
#  reinstall.sh  -  pretty OS chooser for the one-click reinstall engine
# =============================================================================
#  Repo   : https://github.com/wavy07/reinstallation
#  Engine : https://github.com/bin456789/reinstall   (downloaded fresh each run)
#
#  Menu :   curl -fsSL https://raw.githubusercontent.com/wavy07/reinstallation/main/reinstall.sh -o reinstall.sh
#           bash reinstall.sh
#
#  What it does when you pick  Ubuntu > 22.04  is exactly:
#           curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
#           chmod +x reinstall.sh
#           ./reinstall.sh ubuntu 22.04
#
#  Direct : bash reinstall.sh ubuntu 22.04          (skips the menu)
#  Other  : bash reinstall.sh --list | reset | --help
#           NO_ANIM=1 bash reinstall.sh             (no animations)
#
#  WARNING: installing an OS ERASES THE WHOLE DISK. OpenVZ / LXC not supported.
# =============================================================================
set -u
export LC_ALL=C.UTF-8 LANG=C.UTF-8 2>/dev/null || true

ENGINE_URLS=(
  "${RI_UPSTREAM:-https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh}"
  "https://cnb.cool/bin456789/reinstall/-/git/raw/main/reinstall.sh"
)
WORKDIR="${RI_WORKDIR:-/root/reinstall-engine}"

# ----------------------------------------------------------------- terminal / colors
COLOR=0; ANIM=0
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then COLOR=1; fi
if [ "$COLOR" -eq 1 ] && [ "${NO_ANIM:-0}" != "1" ] && [ -z "${RI_NO_ANIM:-}" ]; then ANIM=1; fi

if [ "$COLOR" -eq 1 ]; then
  R=$'\033[0;31m'; G=$'\033[0;32m'; Y=$'\033[1;33m'; B=$'\033[0;34m'; P=$'\033[0;35m'
  C=$'\033[0;36m'; W=$'\033[1;37m'; BD=$'\033[1m'; D=$'\033[2m'; N=$'\033[0m'
  OR=$'\033[38;5;208m'; PK=$'\033[38;5;213m'; LG=$'\033[38;5;120m'; SK=$'\033[38;5;81m'
else
  R=''; G=''; Y=''; B=''; P=''; C=''; W=''; BD=''; D=''; N=''; OR=''; PK=''; LG=''; SK=''
fi
GRAD=(39 45 51 50 49 48 84 120 156 192 228 222 216 210 204 198 199 200 201 165 129 93 57 33)

cols=${COLUMNS:-0}
[[ "$cols" =~ ^[0-9]+$ ]] && [ "$cols" -gt 0 ] || cols=$(tput cols 2>/dev/null || echo 52)
[[ "$cols" =~ ^[0-9]+$ ]] || cols=52
BW=$(( cols - 2 )); (( BW > 58 )) && BW=58; (( BW < 40 )) && BW=40     # box width

hide_cursor() { [ "$ANIM" -eq 1 ] && printf '\033[?25l'; return 0; }
show_cursor() { [ "$COLOR" -eq 1 ] && printf '\033[?25h'; return 0; }
nap()         { [ "$ANIM" -eq 1 ] && sleep "${1:-0.02}"; return 0; }
cls()         { if [ "$ANIM" -eq 1 ]; then printf '\033[H\033[2J'; fi; return 0; }
trap 'show_cursor' EXIT
trap 'show_cursor; printf "\n"; exit 130' INT TERM

# ----------------------------------------------------------------- drawing
rep()        { local s; printf -v s '%*s' "$2" ''; printf '%s' "${s// /$1}"; }
strip_ansi() { printf '%s' "$1" | sed -E 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

grad() {   # gradient text
  local s="$1" i out="" n=${#GRAD[@]}
  if [ "$COLOR" -eq 0 ]; then printf '%s' "$s"; return; fi
  for (( i = 0; i < ${#s}; i++ )); do out+=$'\033[1;38;5;'"${GRAD[i % n]}"'m'"${s:i:1}"; done
  printf '%s%s' "$out" "$N"
}

bx_top()  { printf '%s╭%s╮%s\n' "$1" "$(rep ─ $((BW - 2)))" "$N"; }
bx_mid()  { printf '%s├%s┤%s\n' "$1" "$(rep ─ $((BW - 2)))" "$N"; }
bx_bot()  { printf '%s╰%s╯%s\n' "$1" "$(rep ─ $((BW - 2)))" "$N"; }
dx_top()  { printf '%s╔%s╗%s\n' "$1" "$(rep ═ $((BW - 2)))" "$N"; }
dx_bot()  { printf '%s╚%s╝%s\n' "$1" "$(rep ═ $((BW - 2)))" "$N"; }
bx_row() {   # color text
  local plain pad
  plain="$(strip_ansi "$2")"; pad=$(( BW - 4 - ${#plain} )); (( pad < 0 )) && pad=0
  printf '%s│%s %s%*s %s│%s\n' "$1" "$N" "$2" "$pad" "" "$1" "$N"; nap 0.006
}
dx_center() {   # color text
  local plain total left right
  plain="$(strip_ansi "$2")"; total=$(( BW - 2 - ${#plain} )); (( total < 0 )) && total=0
  left=$(( total / 2 )); right=$(( total - left ))
  printf '%s║%s%*s%s%*s%s║%s\n' "$1" "$N" "$left" "" "$2" "$right" "" "$1" "$N"; nap 0.02
}
bx_center() {
  local plain total left right
  plain="$(strip_ansi "$2")"; total=$(( BW - 2 - ${#plain} )); (( total < 0 )) && total=0
  left=$(( total / 2 )); right=$(( total - left ))
  printf '%s│%s%*s%s%*s%s│%s\n' "$1" "$N" "$left" "" "$2" "$right" "" "$1" "$N"; nap 0.006
}

die()  { show_cursor; echo -e "\n  ${R}✗ $*${N}" >&2; exit 1; }
warn() { echo -e "  ${Y}! $*${N}"; }
ok()   { echo -e "  ${G}✓${N} $*"; }
info() { echo -e "  ${SK}ℹ${N} ${D}$*${N}"; }
have() { command -v "$1" >/dev/null 2>&1; }

banner() {
  echo
  dx_top "$C"
  dx_center "$C" "$(grad '░▒▓  O S   R E I N S T A L L E R  ▓▒░')"
  dx_center "$C" "${D}one-click · official installers · visibleTech🦜${N}"
  dx_bot "$C"
}

title() {   # compact header for sub screens
  echo
  bx_top "$C"
  bx_center "$C" "$(grad "$1")"
  [ -n "${2:-}" ] && bx_center "$C" "${D}$2${N}"
  bx_bot "$C"
}

# ----------------------------------------------------------------- input (works with curl | bash too)
exec 3<&0
if [ ! -t 0 ] && [ -z "${RI_NO_TTY:-}" ] && ( : </dev/tty ) 2>/dev/null; then exec 3</dev/tty; fi

ask() {   # prompt  varname  [default]
  local __p="$1" __v="$2" __d="${3:-}" __in=""
  if [ -n "$__d" ]; then
    printf '  %s❯%s %s %s[%s]%s: ' "$OR" "$N" "$__p" "$D" "$__d" "$N"
  else
    printf '  %s❯%s %s: ' "$OR" "$N" "$__p"
  fi
  IFS= read -r -u 3 __in || { echo; exit 1; }
  printf -v "$__v" '%s' "${__in:-$__d}"
}
ask_secret() {
  local __p="$1" __v="$2" __in=""
  printf '  %s❯%s %s: ' "$OR" "$N" "$__p"
  IFS= read -r -s -u 3 __in || { echo; exit 1; }
  echo
  printf -v "$__v" '%s' "$__in"
}
pause() { local x; printf '\n  %sPress Enter to continue...%s' "$D" "$N"; IFS= read -r -u 3 x || true; }

# ----------------------------------------------------------------- animated helpers
SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
spin_run() {   # label cmd...
  local label="$1"; shift
  local start=$SECONDS rc pid i=0
  if [ "$ANIM" -eq 1 ]; then
    ( "$@" ) >/dev/null 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r  %s%s%s %s %s(%ds)%s\033[K' "$C" "${SPIN[i % 10]}" "$N" "$label" "$D" $(( SECONDS - start )) "$N"
      i=$(( i + 1 )); sleep 0.08
    done
    wait "$pid"; rc=$?
    printf '\r\033[K'
  else
    ( "$@" ) >/dev/null 2>&1; rc=$?
  fi
  if [ "$rc" -eq 0 ]; then
    echo -e "  ${G}✓${N} $label ${D}($(( SECONDS - start ))s)${N}"
  else
    echo -e "  ${R}✗ $label${N}"
  fi
  return "$rc"
}

progress() {   # label  percent_from  percent_to
  local label="$1" p="$2" to="$3" w=26 f
  if [ "$ANIM" -eq 1 ]; then
    while (( p < to )); do
      p=$(( p + 2 )); (( p > to )) && p=$to
      f=$(( p * w / 100 ))
      printf '\r  %s%s%s%s%s %3d%% %s\033[K' "$LG" "$(rep █ "$f")" "$D" "$(rep ░ $((w - f)))" "$N" "$p" "$label"
      sleep 0.012
    done
    printf '\n'
  else
    printf '  [%3d%%] %s\n' "$to" "$label"
  fi
}

countdown() {
  [ "$ANIM" -eq 1 ] || return 0
  local i
  for i in 3 2 1; do
    printf '\r  %s🚀 Starting in %s%d%s %s(Ctrl+C to abort)%s\033[K' "$Y" "$BD$W" "$i" "$N$Y" "$D" "$N"
    sleep 1
  done
  printf '\r\033[K'
}

# ----------------------------------------------------------------- server info
sys_info() {
  local host ip os arch boot ram disk
  host=$(hostname 2>/dev/null || echo "server")
  ip=$(hostname -I 2>/dev/null | awk '{print $1}'); ip=${ip:-n/a}
  os=$( . /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Linux}" ); os=${os:-Linux}
  arch=$(uname -m 2>/dev/null || echo "?")
  if [ -d /sys/firmware/efi ]; then boot="EFI"; else boot="BIOS"; fi
  ram=$(free -m 2>/dev/null | awk '/^Mem:/{print $2" MB"}'); ram=${ram:-n/a}
  disk=$(lsblk -dnbo SIZE,TYPE 2>/dev/null | awk '$2=="disk"{s+=$1} END{if(s>0) printf "%.0f GB", s/1073741824}'); disk=${disk:-n/a}
  VIRT=""
  if have systemd-detect-virt; then VIRT=$(systemd-detect-virt 2>/dev/null || true); fi
  VIRT=${VIRT:-none}
  INFO_HOST="$host"; INFO_IP="$ip"; INFO_OS="$os"; INFO_ARCH="$arch"
  INFO_BOOT="$boot"; INFO_RAM="$ram"; INFO_DISK="$disk"
}

show_info() {
  local vcol="$LG"
  case "$VIRT" in openvz|lxc|lxc-libvirt) vcol="$R" ;; esac
  bx_top "$B"
  bx_row "$B" "${W}SERVER${N}"
  bx_mid "$B"
  bx_row "$B" "${SK}Host   ${N}: ${INFO_HOST:0:20}  ${D}${INFO_IP}${N}"
  bx_row "$B" "${SK}System ${N}: ${INFO_OS:0:34}"
  bx_row "$B" "${SK}CPU    ${N}: ${INFO_ARCH}   ${SK}Boot${N}: ${INFO_BOOT}"
  bx_row "$B" "${SK}Memory ${N}: ${INFO_RAM}   ${SK}Disk${N}: ${INFO_DISK}"
  bx_row "$B" "${SK}Virt   ${N}: ${vcol}${VIRT}${N}"
  bx_bot "$B"
}

# ----------------------------------------------------------------- supported systems
NAMES=(); KEYS=(); VERS=(); TYPES=(); SHORT=()
add() { NAMES+=("$1"); KEYS+=("$2"); VERS+=("$3"); TYPES+=("$4"); SHORT+=("$5"); }

add "Ubuntu"         ubuntu      "18.04 20.04 22.04 24.04 26.04"  ver     "18.04 - 26.04"
add "Debian"         debian      "9 10 11 12 13"                  ver     "9 - 13"
add "Kali Linux"     kali        "last-snapshot rolling"          ver     "rolling"
add "Alpine"         alpine      "3.21 3.22 3.23 3.24"            ver     "3.21 - 3.24"
add "AlmaLinux"      almalinux   "8 9 10"                         ver     "8 - 10"
add "Rocky Linux"    rocky       "8 9 10"                         ver     "8 - 10"
add "Oracle Linux"   oracle      "8 9 10"                         ver     "8 - 10"
add "CentOS Stream"  centos      "9 10"                           ver     "9 - 10"
add "Fedora"         fedora      "43 44"                          ver     "43 - 44"
add "Anolis OS"      anolis      "7 8 23"                         ver     "7, 8, 23"
add "OpenCloudOS"    opencloudos "8 9 23"                         ver     "8, 9, 23"
add "openEuler"      openeuler   "20.03 22.03 24.03 26.09"        ver     "20.03 - 26.09"
add "openSUSE"       opensuse    "16.0 tumbleweed"                ver     "16.0, tumbleweed"
add "NixOS"          nixos       "26.05"                          ver     "26.05"
add "Arch Linux"     arch        ""                               rolling "rolling"
add "Gentoo"         gentoo      ""                               rolling "rolling"
add "AOSC OS"        aosc        ""                               rolling "rolling"
add "fnOS"           fnos        "1"                              ver     "1"
add "FygoOS"         fygoos      "1"                              ver     "1"
add "Red Hat"        redhat      ""                               redhat  "qcow2 link"
NLINUX=${#NAMES[@]}

print_list_plain() {
  local i
  for i in "${!NAMES[@]}"; do printf '%2d) %-14s %s\n' $((i + 1)) "${NAMES[i]}" "${SHORT[i]}"; done
  echo "Windows (ISO), DD image, Alpine Live, netboot.xyz are in the main menu."
}

# ----------------------------------------------------------------- checks
check_env() {
  [ -n "${BASH_VERSION:-}" ] || die "Run this with bash:  bash reinstall.sh"
  [ "$(id -u)" -eq 0 ] || die "Run as root (sudo -i)."
  [ "$(uname -s)" = "Linux" ] || die "This script runs on Linux (use reinstall.bat on Windows)."
  have curl || have wget || die "curl or wget is required."
  case "${VIRT:-none}" in
    openvz|lxc|lxc-libvirt)
      [ -z "${RI_FORCE:-}" ] && die "This is a ${VIRT} container. OpenVZ and LXC are not supported by the engine." ;;
  esac
}

# ----------------------------------------------------------------- engine (same as: curl -O ... ; chmod +x ...)
download_engine() {
  local url
  mkdir -p "$WORKDIR" || return 1
  for url in "${ENGINE_URLS[@]}"; do
    rm -f "$WORKDIR/reinstall.sh.new"
    if have curl; then
      curl -fsSL --retry 3 --connect-timeout 10 "$url" -o "$WORKDIR/reinstall.sh.new" 2>/dev/null
    else
      wget -q -T 15 -t 3 -O "$WORKDIR/reinstall.sh.new" "$url" 2>/dev/null
    fi
    if [ -s "$WORKDIR/reinstall.sh.new" ] \
       && head -n 1 "$WORKDIR/reinstall.sh.new" | grep -Eq '^#!.*sh' \
       && bash -n "$WORKDIR/reinstall.sh.new" 2>/dev/null; then
      mv -f "$WORKDIR/reinstall.sh.new" "$WORKDIR/reinstall.sh"
      return 0
    fi
  done
  rm -f "$WORKDIR/reinstall.sh.new"
  return 1
}

mask_args() {
  local a out="" masknext=0
  for a in "${ARGS[@]}"; do
    if [ "$masknext" -eq 1 ]; then out+=" '****'"; masknext=0; continue; fi
    [ "$a" = "--password" ] && masknext=1
    out+=" $(printf '%q' "$a")"
  done
  printf '%s' "${out# }"
}

summary_box() {   # $1 = label
  echo
  bx_top "$OR"
  bx_center "$OR" "${W}READY TO INSTALL${N}"
  bx_mid "$OR"
  bx_row "$OR" "${SK}Target${N} : ${LG}${1}${N}"
  bx_bot "$OR"
  echo -e "\n  ${D}These commands will run:${N}"
  echo -e "  ${G}\$${N} curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh"
  echo -e "  ${G}\$${N} chmod +x reinstall.sh"
  echo -e "  ${G}\$${N} ${W}./reinstall.sh $(mask_args)${N}"
}

confirm_run() {   # $1 destructive|safe   $2 label
  local ans
  summary_box "$2"
  if [ "$1" = "destructive" ]; then
    echo
    bx_top "$R"
    bx_center "$R" "${R}${BD}WARNING${N}"
    bx_row "$R" "This ${BD}ERASES THE WHOLE DISK${N} (all partitions)."
    bx_row "$R" "Keep a backup + provider console (VNC) ready."
    bx_bot "$R"
    ask "Type ${BD}YES${N} to continue" ans
    [ "$ans" = "YES" ] || { echo -e "\n  ${Y}Cancelled - nothing was changed.${N}"; return 1; }
  else
    echo
    ask "Continue? (y/N)" ans "N"
    [[ "$ans" =~ ^[Yy]$ ]] || { echo -e "\n  ${Y}Cancelled.${N}"; return 1; }
  fi
}

run_engine() {
  local rc
  echo
  progress "checking system" 0 25
  spin_run "curl -O reinstall.sh  (download engine)" download_engine \
    || { echo -e "\n  ${R}Could not download the engine - check the network / DNS.${N}"; return 1; }
  progress "preparing" 25 70
  chmod +x "$WORKDIR/reinstall.sh" && ok "chmod +x reinstall.sh"
  progress "ready" 70 100
  countdown
  echo -e "  ${OR}▶ ./reinstall.sh $(mask_args)${N}\n  $(rep ─ $((BW - 4)))\n"
  show_cursor
  # Prefer a real TTY for interactive prompts (username/password) inside the engine.
  # Fall back to fd 3 (prepared by the outer script) when /dev/tty is unavailable.
  if [ -r /dev/tty ] && [ -w /dev/tty ]; then
    ( cd "$WORKDIR" && ./reinstall.sh "${ARGS[@]}" ) </dev/tty
    rc=$?
    if [ "$rc" -eq 126 ]; then      # /root mounted noexec? run it through bash
      ( cd "$WORKDIR" && bash ./reinstall.sh "${ARGS[@]}" ) </dev/tty
      rc=$?
    fi
  else
    ( cd "$WORKDIR" && ./reinstall.sh "${ARGS[@]}" <&3 )
    rc=$?
    if [ "$rc" -eq 126 ]; then
      ( cd "$WORKDIR" && bash ./reinstall.sh "${ARGS[@]}" <&3 )
      rc=$?
    fi
  fi
  echo -e "\n  $(rep ─ $((BW - 4)))"
  if [ "$rc" -eq 0 ]; then
    ok "The engine finished. If it did not reboot by itself, run: ${BD}reboot${N}"
    info "Changed your mind? Run 'bash reinstall.sh reset' before you reboot."
  else
    warn "The engine stopped with code $rc (read the messages above)."
  fi
  return "$rc"
}

# ----------------------------------------------------------------- menus
VERSION=""; ARGS=()

choose_os() {   # sets CHOSEN (index) ; returns 1 on back
  local i choice
  CHOSEN=-1
  while true; do
    cls; title "CHOOSE OPERATING SYSTEM" "step 1 of 2"
    bx_top "$B"
    for i in "${!NAMES[@]}"; do
      bx_row "$B" "$(printf '%s[%2d]%s %-14s %s%s%s' "$OR" $((i + 1)) "$N" "${NAMES[i]}" "$D" "${SHORT[i]}" "$N")"
    done
    bx_mid "$B"
    bx_row "$B" "${Y}[ 0]${N} Back"
    bx_bot "$B"
    ask "Select the OS" choice
    [ "$choice" = "0" ] && return 1
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= NLINUX )); then
      CHOSEN=$(( choice - 1 )); return 0
    fi
    warn "Invalid choice."; sleep 1
  done
}

pick_version() {   # index -> VERSION ("" = latest) ; returns 1 on back
  local idx="$1" name list v i choice n mark
  name="${NAMES[idx]}"; list="${VERS[idx]}"
  local -a arr=($list)
  n=${#arr[@]}
  VERSION=""
  while true; do
    cls; title "$(printf '%s' "${name^^}")" "step 2 of 2 - choose the version"
    bx_top "$B"
    i=1
    for v in "${arr[@]}"; do
      mark=""
      if (( i == n && n > 1 )) && [[ "$v" =~ ^[0-9.]+$ ]]; then mark=" ${LG}★ newest${N}"; fi
      bx_row "$B" "$(printf '%s[%2d]%s %s' "$OR" "$i" "$N" "$v")${mark}"
      i=$(( i + 1 ))
    done
    bx_mid "$B"
    bx_row "$B" "${OR}[ L]${N} Latest ${D}(engine chooses)${N}"
    bx_row "$B" "${OR}[ M]${N} Type a version by hand"
    bx_row "$B" "${Y}[ 0]${N} Back"
    bx_bot "$B"
    ask "Select the version" choice
    case "$choice" in
      0) return 1 ;;
      [Ll]) VERSION=""; return 0 ;;
      [Mm]) ask "Version" VERSION; [ -n "$VERSION" ] && return 0 ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= n )); then
          VERSION="${arr[choice - 1]}"; return 0
        fi
        warn "Invalid choice."; sleep 1 ;;
    esac
  done
}

customize() {   # $1 = yes -> also ask for an SSH key
  local a user pw ssh_port key
  echo
  ask "Set username / password / SSH port / key now? (y/N)" a "N"
  [[ "$a" =~ ^[Yy]$ ]] || { info "Skipped - the engine will ask for them itself (may fail if stdin is not a real TTY)."; return 0; }
  # Username (engine default is root for Linux / administrator for Windows)
  ask "Username (Enter = root/administrator)" user
  if [ -n "$user" ]; then
    # basic sanity: reject characters the engine also rejects
    if grep -q '[][/\\:|<>+=;,?*%@]' <<<"$user"; then
      warn "Username contains invalid characters, skipped."
    else
      ARGS+=(--username "$user")
    fi
  fi
  ask_secret "Password (Enter = random password)" pw
  [ -n "$pw" ] && ARGS+=(--password "$pw")
  ask "SSH port (Enter = skip)" ssh_port
  if [ -n "$ssh_port" ]; then
    if [[ "$ssh_port" =~ ^[0-9]+$ ]] && (( ssh_port >= 1 && ssh_port <= 65535 )); then
      ARGS+=(--ssh-port "$ssh_port")
    else
      warn "Invalid SSH port, skipped."
    fi
  fi
  if [ "${1:-no}" = "yes" ]; then
    ask "SSH public key / URL / github:USER (Enter = skip)" key
    [ -n "$key" ] && ARGS+=(--ssh-key "$key")
  fi
  return 0
}

flow_linux() {
  local idx key type img mini label
  while true; do
    choose_os || return 1
    idx=$CHOSEN; key="${KEYS[idx]}"; type="${TYPES[idx]}"
    ARGS=("$key")
    case "$type" in
      ver)
        pick_version "$idx" || continue
        [ -n "$VERSION" ] && ARGS+=("$VERSION") ;;
      redhat)
        cls; title "RED HAT" "needs an official qcow2 image link"
        info "Get it from https://access.redhat.com/downloads/content/rhel"
        echo; ask "qcow2 image link" img
        [ -n "$img" ] || { warn "A link is required."; sleep 1; continue; }
        ARGS+=("--img=$img") ;;
    esac
    label="${NAMES[idx]}${VERSION:+ $VERSION}"
    [ "$type" = "ver" ] && [ -z "$VERSION" ] && label="${NAMES[idx]} (latest)"
    if [ "$key" = "ubuntu" ]; then
      echo; ask "Minimal Ubuntu install? (y/N)" mini "N"
      [[ "$mini" =~ ^[Yy]$ ]] && ARGS+=(--minimal)
    fi
    customize yes
    confirm_run destructive "$label" || return 1
    run_engine
    return $?
  done
}

flow_windows() {
  local name lang iso rdp ping
  cls; title "WINDOWS" "official ISO - Vista to 11, Server 2008 to 2025"
  info "Examples: Windows 11 Pro | Windows 10 Pro | Windows 11 Enterprise LTSC 2024"
  info "          Windows Server 2022 ServerStandard | Windows Server 2025 ServerDatacenter"
  echo
  ask "Image name" name "Windows 11 Pro"
  ask "Language (en-us, fr-fr, zh-cn, ...)" lang "en-us"
  ask "ISO link (Enter = engine finds it)" iso
  ARGS=(windows --image-name "$name" --lang "$lang")
  [ -n "$iso" ] && ARGS+=(--iso "$iso")
  ask "RDP port (Enter = default)" rdp
  if [ -n "$rdp" ]; then
    if [[ "$rdp" =~ ^[0-9]+$ ]] && (( rdp >= 1 && rdp <= 65535 )); then ARGS+=(--rdp-port "$rdp"); else warn "Invalid RDP port, skipped."; fi
  fi
  ask "Allow ping in the firewall? (y/N)" ping "N"
  [[ "$ping" =~ ^[Yy]$ ]] && ARGS+=(--allow-ping)
  customize no
  confirm_run destructive "$name" || return 1
  run_engine
}

flow_dd() {
  local img
  cls; title "DD IMAGE" "write a raw disk image"
  info "raw / vhd, also .gz .xz .zst .tar .tar.gz .tar.xz .tar.zst"
  echo; ask "Image link" img
  [ -n "$img" ] || { warn "A link is required."; return 1; }
  ARGS=(dd --img "$img")
  customize yes
  confirm_run destructive "DD image" || return 1
  run_engine
}

flow_live() {
  cls; title "ALPINE LIVE OS" "boots in memory - nothing is erased"
  info "Reboot again to return to your old system."
  ARGS=(alpine --hold 1)
  customize yes
  confirm_run safe "Alpine Live OS" || return 1
  run_engine
}

flow_netboot() {
  cls; title "NETBOOT.XYZ" "install other systems by hand from your provider VNC"
  ARGS=(netboot.xyz)
  confirm_run safe "netboot.xyz" || return 1
  run_engine
}

flow_reset() {
  cls; title "CANCEL REINSTALL" "only works before you reboot"
  ARGS=(reset)
  confirm_run safe "cancel pending reinstall" || return 1
  run_engine
}

main_menu() {
  local choice first=1
  while true; do
    cls
    if [ "$first" -eq 1 ]; then banner; first=0; else banner; fi
    echo
    show_info
    echo
    bx_top "$P"
    bx_center "$P" "${W}MAIN MENU${N}"
    bx_mid "$P"
    bx_row "$P" "${OR}[1]${N} ${BD}Choose OS & version${N}  ${D}Linux${N}"
    bx_row "$P" "${OR}[2]${N} Windows               ${D}official ISO${N}"
    bx_row "$P" "${OR}[3]${N} DD a raw disk image"
    bx_row "$P" "${OR}[4]${N} Alpine Live OS        ${D}nothing erased${N}"
    bx_row "$P" "${OR}[5]${N} netboot.xyz           ${D}nothing erased${N}"
    bx_row "$P" "${OR}[6]${N} Cancel a pending reinstall"
    bx_mid "$P"
    bx_row "$P" "${Y}[0]${N} Exit"
    bx_bot "$P"
    ask "Select an option" choice
    case "$choice" in
      1) flow_linux   && exit 0; pause ;;
      2) flow_windows && exit 0; pause ;;
      3) flow_dd      && exit 0; pause ;;
      4) flow_live    && exit 0; pause ;;
      5) flow_netboot && exit 0; pause ;;
      6) flow_reset   && exit 0; pause ;;
      0) echo -e "\n  ${D}Bye!${N}\n"; exit 0 ;;
      *) warn "Invalid choice."; sleep 1 ;;
    esac
  done
}

# ----------------------------------------------------------------- start
case "${1:-}" in
  -h|--help) sed -n '2,21p' "${BASH_SOURCE[0]:-$0}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  --list|list) print_list_plain; exit 0 ;;
esac

hide_cursor
sys_info
check_env
show_cursor

if [ "$#" -gt 0 ]; then
  ARGS=("$@")
  banner
  if [ "$1" = "reset" ]; then confirm_run safe "cancel pending reinstall" || exit 1
  else confirm_run destructive "$*" || exit 1; fi
  run_engine
  exit $?
fi

main_menu
