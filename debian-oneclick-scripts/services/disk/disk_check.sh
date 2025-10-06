#!/bin/bash
# One-click script для комплексной проверки диска в Xubuntu
# Автор: ChatGPT

# Цвета для терминала
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Проверяем наличие пакетов
for pkg in smartmontools hdparm e2fsprogs util-linux whiptail sysstat; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        echo -e "${YELLOW}Устанавливаю недостающий пакет: $pkg${RESET}"
        sudo apt install -y "$pkg"
    fi
done

# Список дисков
DISKS=($(lsblk -dpno NAME,SIZE | grep -E "/dev/" | awk '{print $1 " " $2}'))
MENU=()
for ((i=0; i<${#DISKS[@]}; i+=2)); do
    MENU+=("${DISKS[i]}" "${DISKS[i+1]}")
done

# Выбор диска
DISK=$(whiptail --title "Выбор диска" --menu "Выберите диск для проверки:" 20 70 10 "${MENU[@]}" 3>&1 1>&2 2>&3)
[ -z "$DISK" ] && echo "Отмена пользователем." && exit 1

# Определяем раздел
PART=$(lsblk -pnlo NAME | grep "^$DISK" | grep -E "[0-9]$" | head -n1)
[ -z "$PART" ] && PART="$DISK"

# Файлы отчётов
NOW=$(date +%Y%m%d_%H%M)
REPORT_TXT="disk_report_${NOW}.txt"
REPORT_HTML="disk_report_${NOW}.html"
exec > >(tee -a "$REPORT_TXT") 2>&1

clear
echo -e "${CYAN}=== 🚀 Комплексная проверка диска $DISK ===${RESET}"
echo "Раздел для fsck: $PART"
echo "Отчёт (txt): $REPORT_TXT"
echo "Отчёт (html): $REPORT_HTML"
echo

# Флаги
SMART_STATUS="OK"
BADBLOCKS_STATUS="OK"
FSCK_STATUS="OK"
HDPARM_STATUS="OK"

# === SMART ===
SMART_OUTPUT=$(sudo smartctl -H "$DISK"; sudo smartctl -A "$DISK")
if echo "$SMART_OUTPUT" | grep -q "PASSED"; then SMART_STATUS="OK"; else SMART_STATUS="FAIL"; fi
echo "$SMART_OUTPUT"

# === badblocks ===
BADBLOCKS_OUTPUT=$(sudo badblocks -sv "$DISK" 2>&1)
if echo "$BADBLOCKS_OUTPUT" | grep -q "Pass completed"; then BADBLOCKS_STATUS="OK"; else BADBLOCKS_STATUS="FAIL"; fi
echo "$BADBLOCKS_OUTPUT"

# === fsck ===
if mount | grep -q "$PART"; then
    FSCK_STATUS="SKIPPED"
    FSCK_OUTPUT="Раздел $PART смонтирован — fsck пропущен."
else
    FSCK_OUTPUT=$(sudo fsck -f -v -y "$PART" 2>&1)
    if echo "$FSCK_OUTPUT" | grep -qi "clean"; then FSCK_STATUS="OK"; else FSCK_STATUS="FAIL"; fi
fi
echo "$FSCK_OUTPUT"

# === hdparm ===
HDPARM_OUTPUT=$(sudo hdparm -t "$DISK" 2>&1)
SPEED=$(echo "$HDPARM_OUTPUT" | grep "MB/sec" | awk '{print $11}')
if [ -n "$SPEED" ]; then
    if (( $(echo "$SPEED < 50" | bc -l) )); then HDPARM_STATUS="WARN"; else HDPARM_STATUS="OK"; fi
else
    HDPARM_STATUS="FAIL"
fi
echo "$HDPARM_OUTPUT"

# === iostat ===
IOSTAT_OUTPUT=$(iostat -dx "$DISK" 5 2 2>&1)
echo "$IOSTAT_OUTPUT"

# === Иконки ===
function status_icon() {
    case $1 in
        OK) echo "✅";;
        FAIL) echo "❌";;
        WARN) echo "⚠️";;
        SKIPPED) echo "⏭️";;
    esac
}
function status_class() {
    case $1 in
        OK) echo "ok";;
        FAIL) echo "fail";;
        WARN) echo "warn";;
        SKIPPED) echo "skip";;
    esac
}

# === Итог (терминал) ===
echo -e "${CYAN}=== 📝 Итоговый отчёт ===${RESET}"
echo "SMART:      $(status_icon $SMART_STATUS) $SMART_STATUS"
echo "badblocks:  $(status_icon $BADBLOCKS_STATUS) $BADBLOCKS_STATUS"
echo "fsck:       $(status_icon $FSCK_STATUS) $FSCK_STATUS"
echo "hdparm:     $(status_icon $HDPARM_STATUS) $HDPARM_STATUS"

# === Формируем HTML ===
cat > "$REPORT_HTML" <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<title>Отчёт проверки диска $DISK</title>
<style>
body { font-family: Arial, sans-serif; margin: 20px; background: #f4f4f9; color: #333; }
h1 { color: #0057d9; }
.block { background: #fff; padding: 15px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.ok { color: green; font-weight: bold; }
.fail { color: red; font-weight: bold; }
.warn { color: orange; font-weight: bold; }
.skip { color: gray; font-weight: bold; }
pre { background: #272822; color: #f8f8f2; padding: 10px; border-radius: 5px; overflow-x: auto; }
table { border-collapse: collapse; margin-bottom: 20px; }
td, th { padding: 8px 12px; border: 1px solid #ccc; }
th { background: #0057d9; color: white; }
</style>
</head>
<body>
<h1>📊 Отчёт проверки диска $DISK</h1>

<h2>📋 Сводка</h2>
<table>
<tr><th>Тест</th><th>Статус</th></tr>
<tr><td>SMART</td><td class="$(status_class $SMART_STATUS)">$(status_icon $SMART_STATUS) $SMART_STATUS</td></tr>
<tr><td>Badblocks</td><td class="$(status_class $BADBLOCKS_STATUS)">$(status_icon $BADBLOCKS_STATUS) $BADBLOCKS_STATUS</td></tr>
<tr><td>Fsck ($PART)</td><td class="$(status_class $FSCK_STATUS)">$(status_icon $FSCK_STATUS) $FSCK_STATUS</td></tr>
<tr><td>Hdparm</td><td class="$(status_class $HDPARM_STATUS)">$(status_icon $HDPARM_STATUS) $HDPARM_STATUS</td></tr>
</table>

<div class="block"><h2>SMART</h2><pre>$SMART_OUTPUT</pre></div>
<div class="block"><h2>Badblocks</h2><pre>$BADBLOCKS_OUTPUT</pre></div>
<div class="block"><h2>Fsck ($PART)</h2><pre>$FSCK_OUTPUT</pre></div>
<div class="block"><h2>Hdparm</h2><pre>$HDPARM_OUTPUT</pre></div>
<div class="block"><h2>Iostat</h2><pre>$IOSTAT_OUTPUT</pre></div>

</body>
</html>
EOF

# === Открытие отчетов ===
if command -v xdg-open &>/dev/null; then
    nohup xdg-open "$REPORT_HTML" >/dev/null 2>&1 &
fi
if command -v mousepad &>/dev/null; then
    nohup mousepad "$REPORT_TXT" >/dev/null 2>&1 &
elif command -v gedit &>/dev/null; then
    nohup gedit "$REPORT_TXT" >/dev/null 2>&1 &
fi

echo
echo -e "${GREEN}✅ Проверка завершена!${RESET}"
echo -e "📂 TXT-отчёт:  $REPORT_TXT"
echo -e "🌐 HTML-отчёт: $REPORT_HTML"

