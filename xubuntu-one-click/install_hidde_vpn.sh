#!/bin/bash

echo "🔐 Установка Hidde VPN (официальный клиент)..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# --- 1. Скачиваем .deb пакет ---
HIDDE_DEB="/tmp/hidde.deb"
if [ ! -f "$HIDDE_DEB" ]; then
    echo "📥 Скачиваем Hidde VPN..."
    wget -q https://cdn.hidde.io/download/linux/hidde-latest.deb -O "$HIDDE_DEB"
fi

# --- 2. Устанавливаем зависимости ---
sudo apt install -y libappindicator3-1 libnotify4

# --- 3. Устанавливаем пакет ---
if [ -f "$HIDDE_DEB" ]; then
    echo "📦 Устанавливаем Hidde..."
    sudo apt install -y "$HIDDE_DEB"
    rm -f "$HIDDE_DEB"
    print_status "Hidde VPN установлен."
else
    print_warning "Не удалось скачать Hidde. Проверь интернет или сайт: https://hidde.io"
    exit 1
fi

# --- 4. Проверяем иконку ---
DESKTOP_FILE="/usr/share/applications/io.hidde.Hidde.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    # Исправляем иконку, если нужно
    if ! grep -q "Icon=io.hidde.Hidde" "$DESKTOP_FILE"; then
        sudo sed -i 's/Icon=.*/Icon=io.hidde.Hidde/' "$DESKTOP_FILE"
    fi
    print_status "Иконка Hidde настроена."
fi

# --- 5. Обновляем кэш ---
sudo update-desktop-database
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null

print_status "Готово! Запусти Hidde из меню приложений."