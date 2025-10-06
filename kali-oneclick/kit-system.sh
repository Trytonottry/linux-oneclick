#!/usr/bin/env bash
# kit-system.sh — System & Network OneClick Kit for Kali (updated)
set -euo pipefail
BASE_DIR="$HOME/oneclick_kits/system"
mkdir -p "$BASE_DIR"

function check_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Требуется $1 — установите и повторите."; return 1; }
}

function update_system() {
  echo "Обновление системы..."
  sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y

  # optional updates for some pentest tooling
  if command -v msfupdate >/dev/null 2>&1; then
    echo "Updating Metasploit..."
    sudo msfupdate || true
  fi

  if command -v pip3 >/dev/null 2>&1; then
    echo "Updating pip packages (user)..."
    pip3 install --user --upgrade pip
    # optionally upgrade outdated pip packages (commented out by default)
    # pip3 list --outdated --format=freeze | cut -d'=' -f1 | xargs -r -n1 pip3 install --user -U
  fi

  # Snap updates (if snap is installed)
  if command -v snap >/dev/null 2>&1; then
    echo "Refreshing snap packages..."
    sudo snap refresh || echo "snap refresh failed or requires snapd to be running"
  else
    echo "snap not installed — пропускаю snap refresh."
  fi

  # Flatpak updates (if flatpak is installed)
  if command -v flatpak >/dev/null 2>&1; then
    echo "Updating flatpak runtimes/apps..."
    # -y to auto-confirm; some systems may prompt for sudo depending on config
    flatpak update -y || echo "flatpak update failed or no remotes configured"
  else
    echo "flatpak not installed — пропускаю flatpak update."
  fi

  echo "Обновление завершено."
}

function wifi_fix() {
  echo "Попытка исправить Wi-Fi..."
  sudo rfkill unblock all || true
  sudo systemctl restart NetworkManager || sudo service NetworkManager restart || true
  echo "Wi-Fi: status:"
  nmcli device status
}

function vpn_connect() {
  if ! check_cmd openvpn; then return 1; fi
  echo "Список .ovpn в $HOME/vpn_profiles (создайте каталог и поместите профили):"
  ls -1 "$HOME/vpn_profiles"/*.ovpn 2>/dev/null || echo "Профилей нет"
  read -rp "Имя профиля (файл .ovpn): " prof
  if [[ ! -f "$HOME/vpn_profiles/$prof" ]]; then
    echo "Файл не найден."
    return 1
  fi
  sudo openvpn --config "$HOME/vpn_profiles/$prof"
}

TOR_ENABLED=0
function tor_proxy_toggle() {
  if (( TOR_ENABLED == 0 )); then
    echo "Включаю Tor (установите tor и privoxy при необходимости)..."
    sudo systemctl start tor || sudo service tor start || true
    echo "Tor включён. Настройте приложения на использование SOCKS5 localhost:9050"
    TOR_ENABLED=1
  else
    echo "Отключаю Tor..."
    sudo systemctl stop tor || sudo service tor stop || true
    TOR_ENABLED=0
  fi
}

function set_anon_mode() {
  echo "WARNING: This will change MAC, hostname, and clear some logs."
  read -rp "Продолжить? (y/N): " ans
  [[ "$ans" =~ ^[Yy] ]] || { echo "Отменено."; return 0; }
  # randomize MAC for first network interface found
  IFACE=$(nmcli device status | awk '/wifi|ethernet/ {print $1; exit}')
  if [[ -n "$IFACE" ]]; then
    sudo ip link set "$IFACE" down
    if command -v macchanger >/dev/null 2>&1; then
      sudo macchanger -r "$IFACE" || true
    else
      echo "macchanger не установлен — пропускаю смену MAC."
    fi
    sudo ip link set "$IFACE" up
    echo "MAC changed/attempted for $IFACE"
  fi
  NEWHOST="kali-$(date +%s | sha256sum | head -c6)"
  echo "Устанавливаю hostname -> $NEWHOST"
  sudo hostnamectl set-hostname "$NEWHOST" || true
  # clear bash history and journal (careful)
  history -c && rm -f ~/.bash_history || true
  if command -v journalctl >/dev/null 2>&1; then
    sudo journalctl --rotate || true
    sudo journalctl --vacuum-time=1s || true
  fi
  echo "Анонимный режим включён."
}

function show_menu() {
  while true; do
    cat <<EOF
=== System & Network Kit ===
1) Update system (apt, pip, msfupdate, snap, flatpak)
2) Wi-Fi fix
3) VPN connect (openvpn)
4) Tor proxy toggle
5) Set anonymous mode (MAC/hostname/clear logs)
0) Exit
EOF
    read -rp "Choice: " c
    case $c in
      1) update_system;;
      2) wifi_fix;;
      3) vpn_connect;;
      4) tor_proxy_toggle;;
      5) set_anon_mode;;
      0) exit 0;;
      *) echo "Неверный выбор";;
    esac
  done
}

show_menu
