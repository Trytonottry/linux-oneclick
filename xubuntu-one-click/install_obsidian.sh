#!/bin/bash

echo "📦 Установка Obsidian с корректной иконкой и поддержкой Xubuntu..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# --- 1. Удаляем Snap-версию (если есть) ---
if snap list | grep -q "obsidian"; then
    echo "🗑️  Удаляем Snap-версию Obsidian..."
    sudo snap remove obsidian
fi

# --- 2. Устанавливаем через Flatpak ---
if ! command -v flatpak &> /dev/null; then
    echo "📦 Устанавливаем Flatpak..."
    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

echo "📥 Устанавливаем Obsidian через Flatpak..."
flatpak install -y flathub md.obsidian.Obsidian

# --- 3. Экспортируем .desktop файл ---
mkdir -p ~/.local/share/applications
ln -sf ~/.local/share/flatpak/exports/share/applications/md.obsidian.Obsidian.desktop ~/.local/share/applications/

print_status "Obsidian установлен через Flatpak — иконка будет работать."

# --- 4. Исправление чёрного окна (если нужно) ---
# Obsidian на Electron — может зависать без --disable-gpu
WRAPPER="$HOME/.local/bin/obsidian"
mkdir -p "$(dirname "$WRAPPER")"

cat > "$WRAPPER" << 'EOF'
#!/bin/bash
# Запуск Obsidian с отключённым GPU (если нужно)
flatpak run --env=OBSIDIAN_DISABLE_GPU=1 md.obsidian.Obsidian "$@"
EOF

chmod +x "$WRAPPER"

# Создаём кастомный .desktop файл с обёрткой
cat > ~/.local/share/applications/obsidian-custom.desktop << EOF
[Desktop Entry]
Name=Obsidian
Comment=Knowledge base that works on top of a local folder of plain text Markdown files.
Exec=$WRAPPER
Icon=md.obsidian.Obsidian
Terminal=false
Type=Application
Categories=Office;
StartupWMClass=obsidian
EOF

chmod +x ~/.local/share/applications/obsidian-custom.desktop

print_status "Создана обёртка для Obsidian с защитой от чёрного окна."

# --- 5. Обновляем кэш ---
update-desktop-database ~/.local/share/applications
gtk-update-icon-cache -f ~/.local/share/icons/hicolor 2>/dev/null

# --- 6. Перезапускаем панель и Plank ---
xfce4-panel -r 2>/dev/null
if pgrep -x "plank" > /dev/null; then
    pkill plank && sleep 1 && plank &
fi

echo ""
print_status "Obsidian готов к работе!"
echo "💡 Используй 'obsidian-custom' в меню или на панели."