#!/bin/bash

set -e

# === Настройки ===
USERNAME="${SUDO_USER:-$(whoami)}"
if [ "$USERNAME" = "root" ]; then
    echo "❌ Скрипт не должен запускаться от root. Используйте обычного пользователя с sudo."
    exit 1
fi

echo "🚀 Устанавливаем Hyprland и зависимости для пользователя: $USERNAME"

# === 1. Обновление системы ===
echo "🔄 Обновляем систему..."
sudo pacman -Syu --noconfirm

# === 2. Установка основных зависимостей ===
echo "📦 Устанавливаем графический стек и зависимости Hyprland..."

# Основные пакеты
sudo pacman -S --needed --noconfirm \
    xorg-xwayland \
    wayland \
    wayland-protocols \
    wlroots \
    mesa \
    libglvnd \
    vulkan-icd-loader \
    polkit \
    xdg-desktop-portal-hyprland \
    xdg-utils \
    pipewire \
    pipewire-pulse \
    alsa-utils \
    bluez \
    bluez-utils \
    networkmanager \
    git \
    base-devel

# Драйверы (автоматически подберутся, но можно уточнить)
# Для Intel:
# sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver
# Для AMD:
# sudo pacman -S --noconfirm mesa vulkan-radeon
# Для NVIDIA (только open-source nouveau, proprietary не поддерживается в Wayland без дополнительных телодвижений):
# sudo pacman -S --needed --noconfirm mesa xf86-video-nouveau

# === 3. Установка AUR-хелпера (paru), если не установлен ===
if ! command -v paru &> /dev/null; then
    echo "📥 Устанавливаем paru (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ..
    rm -rf paru
else
    echo "✅ paru уже установлен."
fi

# === 4. Установка Hyprland из AUR ===
echo "🖥️ Устанавливаем Hyprland..."
paru -S --needed --noconfirm hyprland

# === 5. Установка полезных утилит для Wayland ===
echo "🔧 Устанавливаем дополнительные утилиты..."
paru -S --needed --noconfirm \
    wlogout \
    waybar \
    swaybg \
    swaylock \
    grim \
    slurp \
    wl-clipboard \
    foot \
    rofi-lbonn-wayland

# Альтернативы: можно заменить foot → alacritty, rofi → bemenu и т.д.

# === 6. Создание базовой конфигурации Hyprland ===
CONFIG_DIR="$HOME/.config/hypr"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/hyprland.conf" <<EOF
# === Основные настройки ===
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = hyprctl setcursor Bibata-Modern-Classic 24

# Запуск waybar и других сервисов
exec-once = waybar
exec-once = swaybg -i ~/.config/hypr/wallpaper.png 2>/dev/null || true

# === Ввод ===
input {
    kb_layout = us,ru
    kb_options = grp:alt_shift_toggle
    repeat_rate = 50
    repeat_delay = 300
    natural_scroll = false
}

# === Монитор ===
monitor = ,preferred,auto,1

# === Окна ===
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
}

# === Декорации ===
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
}

# === Анимации ===
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
}

# === Привязки клавиш ===
$mainMod = SUPER

# Запуск терминала
bind = $mainMod, Return, exec, foot

# Запуск rofi
bind = $mainMod, D, exec, rofi -show drun

# Закрытие окна
bind = $mainMod, Q, killactive,

# Переключение окон
bind = $mainMod, J, cyclenext,
bind = $mainMod, K, cycleprev,

# Полноэкранный режим
bind = $mainMod, F, fullscreen,

# Скриншот области
bind = , Print, exec, grim -g \"\$(slurp)\" - | wl-copy

# Выход из сессии
bind = $mainMod SHIFT, E, exec, wlogout

# Перезапуск Hyprland
bind = $mainMod SHIFT, R, reload

# === Рабочие пространства ===
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5

# Перемещение окна на рабочее пространство
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
EOF

# === 7. Создание простого конфига для waybar (опционально) ===
WAYBAR_DIR="$HOME/.config/waybar"
mkdir -p "$WAYBAR_DIR"

cat > "$WAYBAR_DIR/config" <<EOF
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["network", "pulseaudio", "cpu", "memory", "battery", "clock"],
    "hyprland/window": {
        "max-length": 50
    },
    "clock": {
        "format": "{:%H:%M}"
    }
}
EOF

cat > "$WAYBAR_DIR/style.css" <<EOF
* {
    border: none;
    border-radius: 0;
    font-family: monospace;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(0, 0, 0, 0.7);
    color: white;
}

#workspaces button {
    padding: 0 10px;
    background: transparent;
    color: #ffffff;
}

#workspaces button.focused {
    background: #33ccff;
    color: #000000;
}
EOF

# === 8. Разрешение запуска через Display Manager (если используется SDDM/GDM/Ly) ===
# Создаём .desktop файл
sudo mkdir -p /usr/share/wayland-sessions
cat <<EOF | sudo tee /usr/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF

# === 9. Советы пользователю ===
echo "✅ Hyprland установлен и настроен!"
echo ""
echo "💡 Дальнейшие шаги:"
echo " - Перезагрузитесь или выйдите из текущей сессии."
echo " - В меню входа (SDDM/GDM/Ly) выберите 'Hyprland'."
echo " - Если используете автозапуск без DM: добавьте в ~/.bash_profile:"
echo "     export XDG_SESSION_TYPE=wayland"
echo "     export XDG_CURRENT_DESKTOP=Hyprland"
echo "     exec Hyprland"
echo ""
echo "🎨 Советы:"
echo " - Положите обои в ~/.config/hypr/wallpaper.png для фона"
echo " - Настройте ~/.config/foot/foot.ini для терминала foot"
echo " - Документация: https://wiki.hyprland.org/"
