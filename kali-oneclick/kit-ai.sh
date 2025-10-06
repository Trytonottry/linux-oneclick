#!/usr/bin/env bash
# kit-ai.sh — Dev / AI Kit (analysis helpers)
set -euo pipefail
WORK="$HOME/oneclick_kits/ai"
mkdir -p "$WORK"

function exploit_summarizer() {
  read -rp "Path to searchsploit output or file: " f
  [[ -f "$f" ]] || { echo "Файл не найден"; return 1; }
  echo "Summarizing exploits (local simple summarizer)..."
  awk 'BEGIN{ORS="\n\n"} {print NR". "$0}' "$f" > "$WORK/exploit_list.txt"
  echo "Manual review recommended. Saved as $WORK/exploit_list.txt"
  # If you have 'jq' and OPENAI_API_KEY set, you could call API here (not included by default).
}

function ai_recon() {
  read -rp "Nmap/scan folder or file: " f
  [[ -e "$f" ]] || { echo "Не найден."; return 1; }
  echo "Parsing and producing suggestions..."
  # naive parser: find open ports and services
  grep -E "^[0-9]+/tcp" "$f" 2>/dev/null || grep -E "open" "$f" 2>/dev/null || true
  echo "Для расширенного анализа подключите LLM: export OPENAI_API_KEY=..."
  echo "(Шаблон интеграции доступен — могу дописать если нужно.)"
}

function menu() {
  while true; do
    cat <<EOF
=== Dev / AI Kit ===
1) Exploit summarizer (summarize searchsploit output)
2) AI-assisted recon (parse scans and produce action items — local)
0) Exit
EOF
    read -rp "Choice: " c
    case $c in
      1) exploit_summarizer;;
      2) ai_recon;;
      0) exit 0;;
      *) echo "Bad";;
    esac
  done
}

menu
