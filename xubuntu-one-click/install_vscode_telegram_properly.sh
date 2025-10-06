#!/bin/bash

echo "📦 Установка VS Code и Telegram Desktop с корректными иконками..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# --- 1. Удаляем Snap-версии (если есть) ---
if snap list | grep -q "code"; then
    echo "🗑️  Удаляем Snap-версию VS Code..."
    sudo snap remove code
fi

if snap list | grep -q "telegram-desktop"; then
    echo "🗑️  Удаляем Snap-версию Telegram..."
    sudo snap remove telegram-desktop
fi

# --- 2. Устанавливаем VS Code через официальный APT ---
echo "📥 Устанавливаем VS Code через APT (рекомендуется для XFCE)..."

# Добавляем ключ Microsoft
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg > /dev/null

# Добавляем репозиторий
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list

# Устанавливаем
sudo apt update
sudo apt install -y code

print_status "VS Code установлен через APT — иконка будет работать корректно."

# --- 3. Устанавливаем Telegram через Flatpak ---
echo "📥 Устанавливаем Telegram Desktop через Flatpak..."

# Убедимся, что Flatpak установлен
if ! command -v flatpak &> /dev/null; then
    echo "📦 Устанавливаем Flatpak..."
    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Устанавливаем Telegram
flatpak install -y flathub org.telegram.desktop

# Экспортируем .desktop файл в систему (для видимости в меню)
flatpak override --user --env=GTK_USE_PORTAL=1 org.telegram.desktop 2>/dev/null
mkdir -p ~/.local/share/applications
ln -sf ~/.local/share/flatpak/exports/share/applications/org.telegram.desktop ~/.local/share/applications/

print_status "Telegram Desktop установлен через Flatpak — иконка будет отображаться корректно."

# --- 4. Обновляем кэш приложений и иконок ---
echo "🔄 Обновляем кэш приложений и иконок..."

# Обновляем кэш .desktop-файлов
sudo update-desktop-database
update-desktop-database ~/.local/share/applications

# Обновляем кэш иконок
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null
gtk-update-icon-cache -f ~/.local/share/icons/hicolor 2>/dev/null

# Перезапускаем панель и Plank
xfce4-panel -r 2>/dev/null
if pgrep -x "plank" > /dev/null; then
    pkill plank && sleep 1 && plank &
fi

print_status "Кэш обновлён. Иконки должны отображаться корректно."

# --- 5. Финал ---
echo ""
echo -e "${GREEN}🎉 VS Code и Telegram установлены правильно!${NC}"
echo ""
echo "💡 Советы:"
echo " • Перезапусти сеанс (Log Out → Log In), чтобы убедиться, что всё работает."
echo " • Иконки теперь будут отображаться везде: панель, Plank, Whisker Menu."
echo " • В будущем избегай установки приложений через Snap в XFCE."
echo ""
print_status "Готово! Приятной работы 🦊🧩"