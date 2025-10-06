#!/bin/bash

echo "🔧 Исправление иконок Firefox и VS Code в XFCE..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# --- 1. Функция для обновления кэша иконок ---
update_icon_cache() {
    echo "🔄 Обновляем кэш иконок..."
    gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null
    gtk-update-icon-cache -f ~/.local/share/icons/hicolor 2>/dev/null
    xfce4-panel -r 2>/dev/null  # перезапуск панели
    if pgrep -x "plank" > /dev/null; then
        pkill plank && sleep 1 && plank &
    fi
}

# --- 2. Исправление иконки Firefox ---
fix_firefox_icon() {
    DESKTOP_FILE=""
    
    # Ищем .desktop файл Firefox
    if [ -f "/var/lib/snapd/desktop/applications/firefox_firefox.desktop" ]; then
        DESKTOP_FILE="/var/lib/snapd/desktop/applications/firefox_firefox.desktop"
    elif [ -f "$HOME/.local/share/flatpak/exports/share/applications/org.mozilla.firefox.desktop" ]; then
        DESKTOP_FILE="$HOME/.local/share/flatpak/exports/share/applications/org.mozilla.firefox.desktop"
    elif [ -f "/usr/share/applications/firefox.desktop" ]; then
        DESKTOP_FILE="/usr/share/applications/firefox.desktop"
    fi

    if [ -n "$DESKTOP_FILE" ]; then
        echo "🦊 Найден .desktop файл Firefox: $DESKTOP_FILE"
        
        # Проверяем, указана ли иконка правильно
        if grep -q "Icon=firefox" "$DESKTOP_FILE" || grep -q "Icon=org.mozilla.firefox" "$DESKTOP_FILE"; then
            print_status "Иконка Firefox уже корректна."
        else
            # Исправляем Icon= на правильное значение
            sudo sed -i 's/^Icon=.*/Icon=firefox/' "$DESKTOP_FILE" 2>/dev/null || \
            sed -i 's/^Icon=.*/Icon=firefox/' "$DESKTOP_FILE"
            print_status "Иконка Firefox исправлена."
        fi
    else
        print_warning "Firefox не найден или не установлен."
    fi
}

# --- 3. Исправление иконки VS Code ---
fix_vscode_icon() {
    DESKTOP_FILE=""
    
    # Ищем .desktop файл VS Code
    if [ -f "/var/lib/snapd/desktop/applications/code_code.desktop" ]; then
        DESKTOP_FILE="/var/lib/snapd/desktop/applications/code_code.desktop"
    elif [ -f "$HOME/.local/share/flatpak/exports/share/applications/com.visualstudio.code.desktop" ]; then
        DESKTOP_FILE="$HOME/.local/share/flatpak/exports/share/applications/com.visualstudio.code.desktop"
    elif [ -f "/usr/share/applications/code.desktop" ]; then
        DESKTOP_FILE="/usr/share/applications/code.desktop"
    fi

    if [ -n "$DESKTOP_FILE" ]; then
        echo "🧩 Найден .desktop файл VS Code: $DESKTOP_FILE"
        
        if grep -q "Icon=com.visualstudio.code" "$DESKTOP_FILE" || grep -q "Icon=code" "$DESKTOP_FILE"; then
            print_status "Иконка VS Code уже корректна."
        else
            sudo sed -i 's/^Icon=.*/Icon=com.visualstudio.code/' "$DESKTOP_FILE" 2>/dev/null || \
            sed -i 's/^Icon=.*/Icon=com.visualstudio.code/' "$DESKTOP_FILE"
            print_status "Иконка VS Code исправлена."
        fi
    else
        print_warning "VS Code не найден или не установлен."
    fi
}

# --- 4. Убедимся, что иконки доступны в системе ---
ensure_icons_available() {
    # Firefox: иконка обычно есть в hicolor или Papirus
    # VS Code: иконка может отсутствовать — добавим вручную
    
    # Для VS Code: если иконка не найдена — скачаем и установим
    if ! gtk-query-immodules-3.0 2>/dev/null | grep -q "code" && ! [ -f "/usr/share/icons/hicolor/256x256/apps/com.visualstudio.code.png" ]; then
        echo "📥 Устанавливаем иконку VS Code вручную..."
        ICON_DIR="/usr/local/share/icons/hicolor/256x256/apps"
        sudo mkdir -p "$ICON_DIR"
        sudo wget -q https://raw.githubusercontent.com/vinceliuice/Visual-Studio-Code-icon/master/png/256x256.png -O "$ICON_DIR/com.visualstudio.code.png"
        sudo gtk-update-icon-cache -f /usr/local/share/icons/hicolor
        print_status "Иконка VS Code установлена в систему."
    fi
}

# --- Запуск исправлений ---
fix_firefox_icon
fix_vscode_icon
ensure_icons_available
update_icon_cache

echo ""
print_status "Иконки Firefox и VS Code должны отображаться корректно!"
echo "💡 Если иконки всё ещё 'шестерёнки' — перезапусти сеанс (Log Out → Log In)."