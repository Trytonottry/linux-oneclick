#!/bin/bash

echo "🖥️  Запуск полной кастомизации Xubuntu для ПК — красота, скорость, удобство..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_status {
    echo -e "${GREEN}✅ $1${NC}"
}

function print_warning {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function print_error {
    echo -e "${RED}❌ $1${NC}"
}

# --- 1. Обновление системы ---
echo "🔄 Обновляем систему..."
sudo apt update && sudo apt upgrade -y
print_status "Система обновлена."

# --- 2. Установка тем, иконок, курсоров ---
echo "🖌️  Устанавливаем красивые темы и иконки..."

sudo apt install -y \
    xfce4-themes \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    arc-theme

# Иконки: Papirus + Tela
sudo add-apt-repository -y ppa:papirus/papirus
sudo apt update
sudo apt install -y papirus-icon-theme

if ! [ -d "$HOME/.local/share/icons/Tela" ]; then
    mkdir -p "$HOME/.local/share/icons"
    wget -qO- https://github.com/vinceliuice/Tela-icon-theme/archive/refs/heads/master.tar.gz | tar xz -C "$HOME/.local/share/icons"
    mv "$HOME/.local/share/icons/Tela-icon-theme-master" "$HOME/.local/share/icons/Tela"
    gtk-update-icon-cache -f "$HOME/.local/share/icons/Tela"
fi

# Курсоры: Bibata Modern (красивые, крупные — удобно для экрана)
if ! [ -d "$HOME/.icons/Bibata-Modern-Classic" ]; then
    mkdir -p "$HOME/.icons"
    wget -qO- https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.4/Bibata-Modern-Classic.tar.xz | tar xJ -C "$HOME/.icons"
fi

print_status "Темы, иконки и курсоры установлены."

# --- 3. Установка шрифтов ---
echo "🔤 Устанавливаем современные шрифты..."

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# JetBrainsMono Nerd Font (для терминала и кода)
if [ ! -f "$FONT_DIR/JetBrainsMono-Regular-Nerd-Font-Complete.ttf" ]; then
    wget -qO- https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip | zcat > /tmp/jetbrains.zip
    unzip -p /tmp/jetbrains.zip "JetBrains Mono*/Regular/JetBrainsMonoNerdFont-Regular.ttf" > "$FONT_DIR/JetBrainsMono-Regular-Nerd-Font-Complete.ttf"
    rm -f /tmp/jetbrains.zip
fi

# Inter (для интерфейса — чёткий, читаемый на любом экране)
if [ ! -f "$FONT_DIR/Inter-Regular.ttf" ]; then
    wget -q https://github.com/rsms/inter/releases/download/v3.19/Inter-3.19.zip -O /tmp/inter.zip
    unzip -p /tmp/inter.zip "Inter-3.19/Inter (OTF)/*.otf" | head -1 > "$FONT_DIR/Inter-Regular.ttf"
    rm -f /tmp/inter.zip
fi

fc-cache -fv > /dev/null
print_status "Шрифты Inter и JetBrainsMono Nerd установлены."

# --- 4. Применение GTK-настроек ---
echo "🎛️  Настраиваем внешний вид GTK..."

mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name = Arc-Dark
gtk-icon-theme-name = Papirus-Dark
gtk-font-name = Inter 11
gtk-cursor-theme-name = Bibata-Modern-Classic
gtk-cursor-theme-size = 32
gtk-toolbar-style = GTK_TOOLBAR_BOTH
gtk-menu-images = 1
gtk-button-images = 1
gtk-primary-button-warps-slider = false
gtk-application-prefer-dark-theme = true
EOF

# Для GTK2
mkdir -p ~/.gtkrc-2.0
cat > ~/.gtkrc-2.0 << 'EOF'
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Inter 11"
gtk-cursor-theme-name="Bibata-Modern-Classic"
gtk-cursor-theme-size=32
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-menu-images=1
gtk-button-images=1
EOF

print_status "GTK-темы и шрифты применены."

# --- 5. Настройка XFCE: панель, док, меню ---
echo "DockControl Настройка панели и дока..."

# Установка Whisker Menu (лучшее меню приложений)
if ! dpkg -l | grep -q xfce4-whiskermenu-plugin; then
    sudo apt install -y xfce4-whiskermenu-plugin
fi

# Установка Plank (современный док — идеально для ПК)
if ! command -v plank &> /dev/null; then
    sudo apt install -y plank
fi

# Автозапуск Plank
PLANK_DESKTOP="$HOME/.config/autostart/plank.desktop"
mkdir -p "$(dirname "$PLANK_DESKTOP")"
if [ ! -f "$PLANK_DESKTOP" ]; then
    cat > "$PLANK_DESKTOP" << 'EOF'
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
Comment=Simple Dock
EOF
fi

# Настройка панели: убираем лишнее, оставляем только Whisker Menu, группировку окон, часы, звук, сеть
# (Если стандартная панель XFCE — применяем минимальную конфигурацию)
xfconf-query -c xfce4-panel -p /panels/panel-1/autohide -s false 2>/dev/null
xfconf-query -c xfce4-panel -p /panels/panel-1/length -s 100 2>/dev/null
xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=6;x=0;y=0" 2>/dev/null  # верхняя панель

print_status "Панель и док настроены. Перезапустите сеанс для применения."

# --- 6. Включение тёмного режима и улучшение внешнего вида ---
echo "🌙 Включаем тёмный режим везде..."

xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark" 2>/dev/null
xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark" 2>/dev/null
xfconf-query -c xsettings -p /Net/EnableEventSounds -s false 2>/dev/null

# Night Light (если GNOME-совместимо)
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || echo "Night Light не поддерживается — пропускаем."

# Firefox тёмный режим
FIREFOX_PROFILE=$(find "$HOME/.mozilla/firefox" -name "*.default-release" -type d | head -n1)
if [ -n "$FIREFOX_PROFILE" ] && [ ! -f "$FIREFOX_PROFILE/user.js" ]; then
    echo 'user_pref("ui.systemUsesDarkTheme", 1);' >> "$FIREFOX_PROFILE/user.js"
    print_status "Тёмный режим в Firefox включён."
fi

print_status "Тёмный режим активирован."

# --- 7. Установка красивых обоев (для большого экрана) ---
echo "🖼️  Устанавливаем красивые обои по умолчанию..."

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPER_DIR"

DEFAULT_WALLPAPER="$WALLPAPER_DIR/minimal-dark.jpg"
if [ ! -f "$DEFAULT_WALLPAPER" ]; then
    # Обои в стиле "минимализм + тёмные тона" для комфортной работы
    wget -q https://images.unsplash.com/photo-1557682250-33bd709cbe85 -O "$DEFAULT_WALLPAPER"
    # Применяем обои
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$DEFAULT_WALLPAPER" 2>/dev/null
fi

print_status "Обои установлены."

# --- 8. Улучшение UX: уведомления, горячие клавиши, скриншоты ---
echo "🖱️  Улучшаем опыт: уведомления, скриншоты, запуск приложений..."

# Установка Dunst (современные уведомления)
if ! command -v dunst &> /dev/null; then
    sudo apt install -y dunst
    mkdir -p ~/.config/dunst
    cat > ~/.config/dunst/dunstrc << 'EOF'
[global]
    font = Inter 11
    frame_width = 2
    frame_color = "#bd93f9"
    background = "#282a36"
    foreground = "#f8f8f2"
    timeout = 5
    transparency = 15
    corner_radius = 8
EOF
    # Автозапуск Dunst
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/dunst.desktop << 'EOF'
[Desktop Entry]
Type=Application
Exec=dunst
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Dunst
Comment=Notification Daemon
EOF
fi

# Установка Flameshot — лучший инструмент для скриншотов на Linux
if ! command -v flameshot &> /dev/null; then
    sudo apt install -y flameshot
    # Назначаем клавишу PrintScreen на Flameshot
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Shift>s" -n -t string -s "flameshot gui" 2>/dev/null
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/Print" -n -t string -s "flameshot gui" 2>/dev/null
fi

# Установка Rofi — красивый и быстрый запускатель приложений (альтернатива Alt+F2)
if ! command -v rofi &> /dev/null; then
    sudo apt install -y rofi
    mkdir -p ~/.config/rofi
    cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    font: "Inter 12";
    theme: "gruvbox-dark";
}
EOF
    # Горячая клавиша: Super + Пробел
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Super>space" -n -t string -s "rofi -show drun" 2>/dev/null
fi

print_status "Уведомления, скриншоты и запуск приложений настроены."

# --- 9. Дополнительные утилиты для ПК ---
echo "🧰 Устанавливаем утилиты для максимального удобства на ПК..."

sudo apt install -y \
    neofetch \
    bpytop \
    gnome-screenshot \
    xclip \
    arc-menu \
    thunar-archive-plugin \
    file-roller \
    gdebi

# bpytop — красивый системный монитор (лучше htop)
pip3 install bpytop --user 2>/dev/null

# Автозапуск bpytop в терминале по хоткею (Ctrl+Alt+T → bpytop)
if [ -f "$HOME/.config/xfce4/terminal/terminalrc" ]; then
    sed -i 's/CommandExecuted=bash/CommandExecuted=bash -c "bpytop || bash"/' "$HOME/.config/xfce4/terminal/terminalrc" 2>/dev/null
fi

print_status "Утилиты для мониторинга и работы установлены."

# --- 10. Финальная очистка и советы ---
echo "🧹 Очищаем кэш и временные файлы..."

sudo apt autoremove -y
sudo apt autoclean -y
rm -f /tmp/*.zip /tmp/*.tar.* /tmp/*.xz 2>/dev/null

echo ""
echo -e "${GREEN}🎉 КАСТОМИЗАЦИЯ XUBUNTU ДЛЯ ПК ЗАВЕРШЕНА!${NC}"
echo ""
echo "💡 Советы:"
echo " • Выйдите и зайдите снова (Log Out → Log In), чтобы все изменения применились."
echo " • Нажмите ${YELLOW}Super (Win) + Пробел${NC} — для вызова Rofi (быстрый поиск приложений)."
echo " • Нажмите ${YELLOW}PrintScreen${NC} — для создания скриншота через Flameshot."
echo " • Запустите терминал (${YELLOW}Ctrl+Alt+T${NC}) — откроется bpytop (если установлен)."
echo " • Настройте Plank: правый клик → Preferences → расположение, значки, поведение."
echo " • Обои можно сменить через: Настройки → Обои рабочего стола."
echo ""
echo -e "${YELLOW}Рекомендуется перезагрузить систему:${NC}"
echo "   sudo reboot"