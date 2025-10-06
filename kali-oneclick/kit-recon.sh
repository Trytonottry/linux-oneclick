#!/usr/bin/env bash
# kit-recon.sh — Recon OneClick Kit
set -euo pipefail
OUTDIR="$HOME/oneclick_kits/recon"
mkdir -p "$OUTDIR"

function require() { command -v "$1" >/dev/null 2>&1 || { echo "Установите $1"; return 1; } }

function auto_recon() {
  read -rp "Target domain or IP: " target
  ts=$(date +%Y%m%d_%H%M%S)
  dir="$OUTDIR/${target}_$ts"
  mkdir -p "$dir"
  echo "Saving results to $dir"
  ( require nmap && nmap -sC -sV -oA "$dir/nmap" "$target" ) || true
  ( require whois && whois "$target" > "$dir/whois.txt" ) || true
  ( require dig && dig any "$target" +noall +answer > "$dir/dig.txt" ) || true
  ( require whatweb && whatweb -v "$target" > "$dir/whatweb.txt" ) || true
  ( require nikto && nikto -h "http://$target" -o "$dir/nikto.txt" ) || true
  if require wpscan; then wpscan --url "http://$target" --no-update --output "$dir/wpscan.txt" || true; fi
  echo "Recon завершён."
}

function fast_portscan() {
  read -rp "Target: " t
  out="$OUTDIR/${t}_fastscan_$(date +%s).txt"
  nmap -T4 -F -oN "$out" "$t"
  echo "Результат: $out"
}

function mass_recon() {
  read -rp "targets file (one per line): " tf
  [[ -f "$tf" ]] || { echo "Файл не найден"; return 1; }
  while read -r t; do
    auto_recon_target "$t" &
  done < "$tf"
  wait
  echo "Mass recon finished."
}

function auto_recon_target() {
  t="$1"
  mkdir -p "$OUTDIR/$t"
  nmap -sS -Pn -T4 -oN "$OUTDIR/$t/nmap.txt" "$t" || true
}

function subenum() {
  require amass || true
  read -rp "Domain: " d
  base="$OUTDIR/${d}_subenum_$(date +%s)"
  mkdir -p "$base"
  if command -v amass >/dev/null 2>&1; then
    amass enum -passive -d "$d" -o "$base/amass.txt" || true
  fi
  if command -v subfinder >/dev/null 2>&1; then
    subfinder -d "$d" -silent -o "$base/subfinder.txt" || true
  fi
  if command -v assetfinder >/dev/null 2>&1; then
    assetfinder --subs-only "$d" > "$base/assetfinder.txt" || true
  fi
  cat "$base"/*.txt 2>/dev/null | sort -u > "$base/all.txt" || true
  echo "Subdomains saved to $base/all.txt"
}

function dirscan() {
  require ffuf || true
  read -rp "Target URL (http[s]://host): " tgt
  read -rp "Wordlist (path): " w
  out="$OUTDIR/dirscan_$(date +%s).txt"
  ffuf -u "${tgt}/FUZZ" -w "$w" -o "$out" || true
  echo "Dirscan result: $out"
}

function menu() {
  while true; do
    cat <<EOF
=== Recon Kit ===
1) Auto recon (nmap, whois, dig, whatweb, nikto, wpscan)
2) Fast portscan
3) Mass recon (targets file)
4) Subdomain enumeration
5) Directory scan (ffuf/gobuster)
0) Exit
EOF
    read -rp "Choice: " c
    case $c in
      1) auto_recon;;
      2) fast_portscan;;
      3) mass_recon;;
      4) subenum;;
      5) dirscan;;
      0) exit 0;;
      *) echo "Bad choice";;
    esac
  done
}

menu
