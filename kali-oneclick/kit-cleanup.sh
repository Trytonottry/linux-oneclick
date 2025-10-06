#!/usr/bin/env bash
# kit-cleanup.sh — Cleanup & Cover Tracks Kit
set -euo pipefail
BACKUP="$HOME/oneclick_kits/cleanup/backup"
mkdir -p "$BACKUP"

function clean_traces() {
  echo "Будут удалены bash_history, временные файлы и некоторые логи."
  read -rp "Продолжить? (y/N): " a
  [[ "$a" =~ ^[Yy] ]] || { echo "Отменено."; return; }
  history -c
  rm -f ~/.bash_history ~/.cache/*/* 2>/dev/null || true
  sudo journalctl --rotate || true
  sudo journalctl --vacuum-time=1s || true
  echo "Traces cleaned."
}

function restore_defaults() {
  echo "Восстановление сетевых интерфейсов и системных настроек (попытаюсь восстановить NetworkManager)."
  sudo systemctl restart NetworkManager || sudo service NetworkManager restart || true
  echo "Defaults restored (по возможности)."
}

function menu() {
  while true; do
    cat <<EOF
=== Cleanup Kit ===
1) Clean traces (bash history, journal rotate/vacuum)
2) Restore defaults (networking)
0) Exit
EOF
    read -rp "Choice: " c
    case $c in
      1) clean_traces;;
      2) restore_defaults;;
      0) exit 0;;
      *) echo "Bad";;
    esac
  done
}

menu
