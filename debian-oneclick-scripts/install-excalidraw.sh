#!/bin/bash

set -e  # Остановить при ошибке

APP_NAME="Excalidraw"
APP_EXEC="excalidraw"
APPIMAGE_URL="https://github.com/zsviczian/excalidraw-desktop/releases/latest/download/excalidraw-desktop-linux.AppImage"
ICON_URL="https://raw.githubusercontent.com/zsviczian/excalidraw-desktop/main/assets/icons/icon.png"

INSTALL_DIR="$HOME/.local/bin"
APPDIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

# Создаём папки
mkdir -p "$INSTALL_DIR" "$APPDIR" "$ICON_DIR"

# Устанавливаем зависимости
echo "🔹 Устанавливаем зависимости..."
sudo apt update
sudo apt install -y wget libfuse2

# Скачиваем AppImage
echo "🔹 Скачиваем Excalidraw Desktop..."
APPIMAGE_PATH="$INSTALL_DIR/${APP_EXEC}.AppImage"
wget -O "$APPIMAGE_PATH" "$APPIMAGE_URL"
chmod +x "$APPIMAGE_PATH"

# Скачиваем иконку
echo "🔹 Устанавливаем иконку..."
ICON_PATH="$ICON_DIR/${APP_EXEC}.png"
wget -O "$ICON_PATH" "$ICON_URL"

# Создаём .desktop файл
echo "🔹 Создаём ярлык в меню приложений..."
cat > "$APPDIR/${APP_EXEC}.desktop" <<EOF
[Desktop Entry]
Name=$APP_NAME
Exec=$APPIMAGE_PATH
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Graphics;Utility;
Comment=Virtual whiteboard for sketching hand-drawn like diagrams
StartupWMClass=excalidraw-desktop
EOF

# Обновляем базу приложений (для XFCE/Xubuntu)
update-desktop-database "$APPDIR" 2>/dev/null || true

echo ""
echo "✅ Excalidraw Desktop установлен!"
echo "👉 Запустите из меню приложений или командой: $APP_EXEC"
echo "📁 AppImage: $APPIMAGE_PATH"
