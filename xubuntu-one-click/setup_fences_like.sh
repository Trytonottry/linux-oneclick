#!/bin/bash

echo "🪄 Настройка Fences-подобной системы для Xubuntu..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# --- 1. Создаём папку "Fences" на рабочем столе ---
DESKTOP="$HOME/Desktop"
FENCES_DIR="$DESKTOP/Fences"
mkdir -p "$FENCES_DIR"

# --- 2. Создаём ярлыки для часто используемых приложений ---
create_shortcut() {
    local name="$1"
    local exec="$2"
    local icon="$3"
    local desktop_file="$FENCES_DIR/$name.desktop"

    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=$exec
Icon=$icon
Terminal=false
Categories=Utility;
EOF
    chmod +x "$desktop_file"
}

# Примеры ярлыков (настрой под себя!)
create_shortcut "VS Code" "code" "com.visualstudio.code"
create_shortcut "Firefox" "firefox" "firefox"
create_shortcut "Telegram" "flatpak run org.telegram.desktop" "org.telegram.desktop"
create_shortcut "Terminal" "kitty" "kitty"
create_shortcut "Files" "thunar" "system-file-manager"
create_shortcut "Settings" "xfce4-settings-manager" "preferences-system"

print_status "Папка 'Fences' создана на рабочем столе с ярлыками."

# --- 3. Устанавливаем Rofi (если ещё не установлен) ---
if ! command -v rofi &> /dev/null; then
    echo "📦 Устанавливаем Rofi для красивого меню..."
    sudo apt install -y rofi
fi

# --- 4. Создаём скрипт-меню "Fences Menu" ---
FENCES_SCRIPT="$HOME/.local/bin/fences-menu"
mkdir -p "$(dirname "$FENCES_SCRIPT")"

cat > "$FENCES_SCRIPT" << 'EOF'
#!/bin/bash
# Fences-like menu for XFCE using Rofi

entries=(
    "VS Code:code:com.visualstudio.code"
    "Firefox:firefox:firefox"
    "Telegram:flatpak run org.telegram.desktop:org.telegram.desktop"
    "Terminal:kitty:kitty"
    "Files:thunar:system-file-manager"
    "Settings:xfce4-settings-manager:preferences-system"
    "Reboot:sudo reboot:system-reboot"
    "Shutdown:sudo poweroff:system-shutdown"
)

# Форматируем для Rofi
list=""
for entry in "${entries[@]}"; do
    name=$(echo "$entry" | cut -d: -f1)
    list="$list$name\n"
done

# Выбор
chosen=$(echo -e "$list" | rofi -dmenu -i -p "Fences" -theme gruvbox-dark)

# Запуск
if [ -n "$chosen" ]; then
    for entry in "${entries[@]}"; do
        name=$(echo "$entry" | cut -d: -f1)
        cmd=$(echo "$entry" | cut -d: -f2)
        if [ "$chosen" = "$name" ]; then
            if [[ "$cmd" == "sudo "* ]]; then
                pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY bash -c "${cmd#sudo }"
            else
                $cmd &
            fi
            break
        fi
    done
fi
EOF

chmod +x "$FENCES_SCRIPT"

# --- 5. Создаём иконку на рабочем столе для запуска меню ---
FENCES_DESKTOP="$DESKTOP/Fences Menu.desktop"
cat > "$FENCES_DESKTOP" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Fences Menu
Comment=Beautiful app launcher like Windows Fences
Exec=$FENCES_SCRIPT
Icon=preferences-desktop
Terminal=false
Categories=Utility;
EOF
chmod +x "$FENCES_DESKTOP"

print_status "Иконка 'Fences Menu' создана на рабочем столе."

# --- 6. (Опционально) Добавляем горячую клавишу: Super+F ---
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>f" -n -t string -s "$FENCES_SCRIPT" 2>/dev/null
print_status "Горячая клавиша: Super+F → Fences Menu"

# --- 7. Обновляем рабочий стол ---
# XFCE не всегда сразу видит новые .desktop файлы
touch "$DESKTOP"
xfdesktop --reload 2>/dev/null

echo ""
echo -e "${GREEN}🎉 Fences-подобная система готова!${NC}"
echo ""
echo "📁 Папка 'Fences' на рабочем столе — содержит ярлыки."
echo "🖱️  Иконка 'Fences Menu' — открывает красивое меню (как в Fences)."
echo "⌨️  Нажми ${YELLOW}Super+F${NC} — чтобы вызвать меню без рабочего стола."
echo ""
print_status "Совет: перетащи 'Fences Menu' на Plank или панель для быстрого доступа!"