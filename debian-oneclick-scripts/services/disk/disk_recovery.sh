#!/bin/bash
# Disk Recovery Tool with Recovery Score
# Автор: ChatGPT

# Цвета
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"

# Проверка пакетов
for pkg in testdisk; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        echo -e "${YELLOW}Устанавливаю пакет: $pkg${RESET}"
        sudo apt install -y "$pkg"
    fi
done

# Список дисков
DISKS=($(lsblk -dpno NAME,SIZE | grep -E "/dev/" | awk '{print $1 " " $2}'))
MENU=()
for ((i=0; i<${#DISKS[@]}; i+=2)); do
    MENU+=("${DISKS[i]}" "${DISKS[i+1]}")
done

DISK=$(whiptail --title "Выбор диска" --menu "Выберите диск или раздел для анализа:" 20 70 10 "${MENU[@]}" 3>&1 1>&2 2>&3)
[ -z "$DISK" ] && echo "Отмена пользователем." && exit 1

NOW=$(date +%Y%m%d_%H%M)
REPORT_TXT="recovery_report_${NOW}.txt"
REPORT_HTML="recovery_report_${NOW}.html"

exec > >(tee -a "$REPORT_TXT") 2>&1

clear
echo -e "${CYAN}=== 🔍 Инструменты восстановления данных ===${RESET}"
echo "Выбран диск/раздел: $DISK"
echo "📂 TXT-отчёт:  $REPORT_TXT"
echo "🌐 HTML-отчёт: $REPORT_HTML"
echo

ACTION=$(whiptail --title "Выберите действие" --menu "Что сделать с $DISK?" 20 70 10 \
    1 "Проверить структуру разделов (testdisk)" \
    2 "Поиск удалённых файлов (photorec, анализ)" \
    3 "Восстановить файлы в /home/recovery" \
    3>&1 1>&2 2>&3)

[ -z "$ACTION" ] && echo "Отмена пользователем." && exit 1

RESULT=""; STATUS="OK"; DESC=""; SCORE=0

case $ACTION in
    1)
        echo -e "${YELLOW}▶ Анализ структуры разделов (testdisk)...${RESET}"
        RESULT=$(sudo testdisk /log "$DISK" <<< "q" 2>&1)
        DESC="Анализ структуры разделов"
        PARTS_FOUND=$(echo "$RESULT" | grep -c "Partition")
        SCORE=$(( PARTS_FOUND > 0 ? 80 : 20 ))
        ;;
    2)
        echo -e "${YELLOW}▶ Поиск удалённых файлов (photorec)...${RESET}"
        RESULT=$(sudo photorec /log /debug "$DISK" <<< "q" 2>&1)
        DESC="Поиск удалённых файлов"
        FILES_FOUND=$(echo "$RESULT" | grep -o "files found" | wc -l)
        if [[ $FILES_FOUND -gt 0 ]]; then SCORE=70; else SCORE=30; fi
        ;;
    3)
        echo -e "${YELLOW}▶ Восстановление файлов (photorec)...${RESET}"
        RECOVERY_DIR="/home/recovery"
        mkdir -p "$RECOVERY_DIR"
        RESULT=$(sudo photorec /log /d "$RECOVERY_DIR" "$DISK" <<< "q" 2>&1)
        DESC="Восстановление файлов"
        FILES_RECOVERED=$(find "$RECOVERY_DIR" -type f | wc -l)
        if [[ $FILES_RECOVERED -gt 100 ]]; then SCORE=95
        elif [[ $FILES_RECOVERED -gt 0 ]]; then SCORE=70
        else SCORE=10; fi
        ;;
esac

[[ -z "$RESULT" ]] && STATUS="FAIL" && SCORE=0

# === HTML отчёт ===
cat > "$REPORT_HTML" <<EOF
<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<title>Отчёт восстановления данных $DISK</title>
<style>
body { font-family: Arial, sans-serif; margin: 20px; background: #f4f4f9; color: #333; }
h1 { color: #0057d9; }
.block { background: #fff; padding: 15px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.ok { color: green; font-weight: bold; }
.fail { color: red; font-weight: bold; }
pre { background: #272822; color: #f8f8f2; padding: 10px; border-radius: 5px; overflow-x: auto; }
table { border-collapse: collapse; margin-bottom: 20px; }
td, th { padding: 8px 12px; border: 1px solid #ccc; }
th { background: #0057d9; color: white; }
.score { font-size: 1.5em; }
</style>
</head>
<body>
<h1>📊 Отчёт восстановления данных</h1>

<h2>📋 Сводка</h2>
<table>
<tr><th>Диск/раздел</th><th>Операция</th><th>Статус</th><th>Шанс восстановления</th></tr>
<tr>
  <td>$DISK</td>
  <td>$DESC</td>
  <td class="${STATUS,,}">$( [[ "$STATUS" == "OK" ]] && echo "✅ OK" || echo "❌ FAIL")</td>
  <td class="score">${SCORE}%</td>
</tr>
</table>

<div class="block">
<h2>📜 Лог выполнения</h2>
<pre>$RESULT</pre>
</div>

</body>
</html>
EOF

# === Автооткрытие ===
if command -v xdg-open &>/dev/null; then
    nohup xdg-open "$REPORT_HTML" >/dev/null 2>&1 &
fi

echo
echo -e "${GREEN}✅ Работа завершена!${RESET}"
echo "📂 TXT-отчёт:  $REPORT_TXT"
echo "🌐 HTML-отчёт: $REPORT_HTML"

