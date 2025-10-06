#!/usr/bin/env bash
# kit-qol.sh — Quality of Life Kit
set -euo pipefail
WORK="$HOME/oneclick_kits/qol"
mkdir -p "$WORK/reports" "$WORK/screenshots"

function kali_setup() {
  echo "Первичная настройка Kali: установка пакетов и alias."
  read -rp "Установить common tools (nmap, git, python3-pip)? (y/N): " a
  [[ "$a" =~ ^[Yy] ]] || { echo "Пропущено."; return; }
  sudo apt update
  sudo apt install -y nmap git python3-pip zsh htop || true
  # add helpful aliases
  grep -qxF 'alias ll="ls -la"' ~/.bashrc || echo 'alias ll="ls -la"' >> ~/.bashrc
  echo "Setup finished."
}

function screenshotter() {
  read -rp "Количество скриншотов: " n
  for i in $(seq 1 "$n"); do
    filename="$WORK/screenshots/shot_$(date +%Y%m%d_%H%M%S).png"
    import -window root "$filename" 2>/dev/null || grim "$filename" 2>/dev/null || scrot "$filename" 2>/dev/null
    echo "Saved $filename"
    sleep 1
  done
}

function report_builder() {
  read -rp "Папка с отчетами (default current dir): " d
  d=${d:-.}
  out="$WORK/reports/report_$(date +%Y%m%d_%H%M%S).md"
  echo "# Combined Report $(date)" > "$out"
  find "$d" -type f \( -iname "*.txt" -o -iname "*.html" -o -iname "*.xml" -o -iname "*.md" \) -exec sh -c 'echo "---- FILE: {}" >> "$0"; cat "{}" >> "$0"' "$out" {} \;
  echo "Report built: $out"
}

function notes_sync() {
  read -rp "Sync destination (scp user@host:/path) or 'git': " dest
  if [[ "$dest" == "git" ]]; then
    read -rp "Git repo path (local): " repo
    git -C "$repo" add . && git -C "$repo" commit -m "notes sync $(date)" && git -C "$repo" push || true
  else
    read -rp "Local notes dir: " nd
    scp -r "$nd" "$dest"
  fi
  echo "Sync done."
}

function menu() {
  while true; do
    cat <<EOF
=== QoL Kit ===
1) Kali first-run setup (install basics, aliases)
2) Take screenshots (batch)
3) Build combined report (MD)
4) Sync notes (scp or git)
0) Exit
EOF
    read -rp "Choice: " c
    case $c in
      1) kali_setup;;
      2) screenshotter;;
      3) report_builder;;
      4) notes_sync;;
      0) exit 0;;
      *) echo "Bad";;
    esac
  done
}

menu
