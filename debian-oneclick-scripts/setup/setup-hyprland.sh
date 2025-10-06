#!/bin/bash

# ───────────────────────────────────────────────
# 🌌 One-Click установка Hyprland на Debian 12
# Работает с NVIDIA, включает waybar, foot, wofi
# Запуск: sudo bash setup-hyprland.sh
# ───────────────────────────────────────────────

set -euo pipefail

echo "🚀 Установка Hyprland на Debian 12..."

# Проверка: только Debian 12
if ! grep -q "bookworm" /etc/os-release; then
    echo "❗ Этот скрипт предназначен для Debian 12 (bookworm)"
    cat /etc/os-release
    exit 1
fi

# Проверка: запущен через sudo
if [ "$EUID" -ne 0 ]; then
    echo "❗ Запускай: sudo bash $0"
    exit 1
fi

# Пользователь и домашняя папка
USERNAME=$(logname || echo $SUDO_USER)
USERHOME=$(getent passwd "$USERNAME" | cut -d: -f6)

echo "🔧 Пользователь: $USERNAME"
echo "🏠 Домашняя папка: $USERHOME"

# ───────────────────────────────────────────────
# 1. Добавляем backports (для libwlroots-dev)
# ───────────────────────────────────────────────
echo "📦 Добавляем Debian Backports..."
grep -q "bookworm-backports" /etc/apt/sources.list || \
    echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free" | \
    sudo tee -a /etc/apt/sources.list

apt update

# ───────────────────────────────────────────────
# 2. Установка зависимостей
# ───────────────────────────────────────────────
echo "📦 Установка зависимостей..."
apt install -y \
    git cmake meson ninja-build \
    libglm-dev libvulkan-dev glslc \
    libxkbcommon-dev libpixman-1-dev libseat-dev \
    libpugixml-dev libsigc++-2.0-dev libinput-dev \
    libudev-dev libx11-xcb-dev libxcb1-dev \
    libxcb-render0-dev libxcb-composite0-dev \
    libxcb-damage0-dev libxcb-image0-dev \
    libxcb-present-dev libxcb-render-util0-dev \
    libxcb-shm0-dev libxcb-xfixes0-dev \
    libxcb-xinerama0-dev libxcb-xinput-dev \
    libxcb-xkb-dev libxcb-randr0-dev \
    libxcb-shape0-dev libxcb-sync-dev \
    libxcb-xrm-dev libxcb-cursor-dev \
    libxcb-util-dev libxcb-dpms0-dev \
    libevdev-dev libjson-c-dev \
    libwayland-dev libdrm-dev libgbm-dev \
    wayland-protocols \
    libcairo2-dev libpango1.0-dev \
    libgdk-pixbuf2.0-dev libxml2-dev \
    libavif-dev libjpeg-dev libpng-dev \
    libfontconfig1-dev libfreetype-dev \
    libdbus-1-dev libpulse-dev libglib2.0-dev \
    brightnessctl \
    xdg-desktop-portal xdg-desktop-portal-wlr \
    polkitd \
    pipewire wireplumber \
    dbus-user-session \
    libnotify-bin \
    blueman \
    network-manager-gnome \
    pavucontrol

# Установка libwlroots-dev из backports
apt install -y -t bookworm-backports libwlroots-dev

# ───────────────────────────────────────────────
# 3. Установка компонентов Hyprland
# ───────────────────────────────────────────────
cd /tmp || exit

# hyprutils
echo "🔧 Установка hyprutils..."
git clone https://github.com/hyprwm/hyprutils
cd hyprutils
meson setup build --prefix /usr
ninja -C build
sudo ninja -C build install

# hyprlang
echo "🔧 Установка hyprlang..."
cd /tmp
git clone https://github.com/hyprwm/hyprlang
cd hyprlang
meson setup build --prefix /usr
ninja -C build
sudo ninja -C build install

# hyprcursor
echo "🔧 Установка hyprcursor..."
cd /tmp
git clone https://github.com/hyprwm/hyprcursor
cd hyprcursor
meson setup build --prefix /usr
ninja -C build
sudo ninja -C build install

# Hyprland (основной)
echo "🔧 Установка Hyprland..."
cd /tmp
git clone https://github.com/hyprwm/Hyprland
cd Hyprland
meson setup build --prefix /usr
ninja -C build
sudo ninja -C build install

# ───────────────────────────────────────────────
# 4. Установка утилит
# ───────────────────────────────────────────────
echo "📦 Установка waybar, foot, wofi..."
apt install -y \
    waybar \
    foot \
    wofi \
    grim \
    slurp \
    wl-clipboard \
    brightnessctl \
    thunar \
    wlogout

# ───────────────────────────────────────────────
# 5. Создание конфигурации
# ───────────────────────────────────────────────
su - "$USERNAME" -c "
    mkdir -p ~/.config/hypr
    mkdir -p ~/.config/waybar
    mkdir -p ~/.config/foot
"

# Конфиг Hyprland
cat > "$USERHOME/.config/hypr/hyprland.conf" << 'EOF'
monitor=,preferred,auto,1

input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    layout = dwindle
}

dwindle {
    pseudotile = yes
}

animations {
    enabled = yes
    animation = windows, 1, 7, default
    animation = layers, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

exec-once = pipewire &
exec-once = wireplumber &
exec-once = xdg-desktop-portal &
exec-once = xdg-desktop-portal-hyprland &
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec-once = nm-applet --indicator &
exec-once = waybar &
exec-once = swaybg -i /usr/share/backgrounds/debian-blur.png -m fill

bind = SUPER, RETURN, exec, foot
bind = SUPER, Q, killactive,
bind = SUPER, M, togglefloating,
bind = SUPER, F, fullscreen,
bind = SUPER, P, exec, wlogout
bind = SUPER, E, exec, thunar
bind = SUPER, R, exec, wofi --show drun

$mod = SUPER
EOF

# Конфиг Waybar
cat > "$USERHOME/.config/waybar/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["pulseaudio", "network", "battery", "clock"],
    "hyprland/workspaces": {
        "format": "{icon}",
        "on-click": "activate"
    },
    "clock": {
        "format": "📅 {:%d.%m} ⏰ {:%H:%M}"
    },
    "battery": {
        "format": "{icon} {capacity}%",
        "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    }
}
EOF

# Конфиг Foot
cat > "$USERHOME/.config/foot/foot.ini" << 'EOF'
[main]
font=JetBrainsMono Nerd Font:style=Regular:size=10
font-bold=JetBrainsMono Nerd Font:style=Bold
font-italic=JetBrainsMono Nerd Font:style=Italic
font-bold-italic=JetBrainsMono Nerd Font:style=Bold Italic
EOF

# ───────────────────────────────────────────────
# 6. .desktop файл для входа
# ───────────────────────────────────────────────
cat > "/usr/share/wayland-sessions/hyprland.desktop" << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Wayland compositor
Exec=/usr/bin/Hyprland
Type=Application
DesktopNames=Hyprland
Keywords=hypr;hyprland;wayland;tiling
EOF

# ───────────────────────────────────────────────
# 7. Установка Nerd Font
# ───────────────────────────────────────────────
su - "$USERNAME" -c "
    mkdir -p ~/.fonts
    cd ~/.fonts
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip
    fc-cache -fv
"

# ───────────────────────────────────────────────
# 8. Поддержка NVIDIA
# ───────────────────────────────────────────────
echo 'export __GL_YIELD="USLEEP"' >> "$USERHOME/.profile"
echo 'export GBM_BACKEND=nvidia-drm' >> "$USERHOME/.profile"
echo 'export __GL_GSYNC_ALLOWED=0' >> "$USERHOME/.profile"
echo 'export __GL_VRR_ALLOWED=0' >> "$USERHOME/.profile"

# ───────────────────────────────────────────────
# 🎉 Готово!
# ───────────────────────────────────────────────
cat << 'EOF'

✅ Установка Hyprland завершена!

📌 Чтобы войти:
1. Перезагрузи систему: sudo reboot
2. На экране входа (GDM):
   - Нажми на ⚙️ (шестерёнку)
   - Выбери: **Hyprland**

🔑 Горячие клавиши:
- Super + Enter: терминал (foot)
- Super + E: файловый менеджер (thunar)
- Super + R: запуск приложения (wofi)
- Super + Q: закрыть окно
- Super + F: полноэкранный режим
- Super + P: выход (wlogout)

🎨 Иконки и шрифты: Установлен JetBrainsMono Nerd Font.

🚀 Хочешь добавить blur, кастомный wofi или анимации? Напиши — помогу!
EOF

exit 0
