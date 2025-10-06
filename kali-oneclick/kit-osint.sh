#!/usr/bin/env bash
# kit-osint.sh — OSINT & Social Engineering Kit
set -euo pipefail
OUTDIR="$HOME/oneclick_kits/osint"
mkdir -p "$OUTDIR"

function osint_person() {
  read -rp "Имя/ник/почта: " q
  echo "Результаты будут в $OUTDIR/${q}_$(date +%s)"
  odir="$OUTDIR/${q}_$(date +%s)"
  mkdir -p "$odir"
  if command -v sherlock >/dev/null 2>&1; then
    sherlock "$q" -o "$odir/sherlock" || true
  fi
  if command -v theHarvester >/dev/null 2>&1; then
    theHarvester -d "$q" -b all -l 200 -f "$odir/theharvester.html" || true
  fi
  if command -v holehe >/dev/null 2>&1; then
    holehe "$q" | tee "$odir/holehe.txt" || true
  fi
  echo "OSINT done: $odir"
}

function phishing_deploy() {
  echo "ВНИМАНИЕ: Утилита предназначена только для тестирования с согласием!"
  read -rp "Продолжить? (y/N): " a
  [[ "$a" =~ ^[Yy] ]] || { echo "Отменено."; return; }
  if command -v zphisher >/dev/null 2>&1; then
    zphisher
  elif command -v setoolkit >/dev/null 2>&1; then
    sudo setoolkit
  else
    echo "Установите zphisher или setoolkit для использования этой функции."
  fi
}

function metadata_scan() {
  read -rp "Directory with files (default .): " d
  d=${d:-.}
  outfile="$OUTDIR/metadata_$(date +%s).csv"
  echo "file,tag,value" > "$outfile"
  find "$d" -type f -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" | while read -r f; do
    exiftool -csv "$f" >> "$outfile" 2>/dev/null || true
  done
  echo "Metadata CSV: $outfile"
}

function menu() {
  while true; do
    cat <<EOF
=== OSINT Kit ===
1) OSINT by person (sherlock, theHarvester, holehe)
2) Phishing deployer (zphisher / setoolkit) — ONLY FOR AUTHORIZED TESTS
3) Metadata scan (exiftool -> CSV)
0) Exit
EOF
    read -rp "Choice: " c
    case $c in
      1) osint_person;;
      2) phishing_deploy;;
      3) metadata_scan;;
      0) exit 0;;
      *) echo "Bad";;
    esac
  done
}

menu
