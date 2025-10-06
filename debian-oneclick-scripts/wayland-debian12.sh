#!/bin/bash

# ───────────────────────────────────────────────
# 🌐 Полная настройка Wayland на Debian 12
# Активирует Wayland в GDM + проверка NVIDIA
# Запуск: sudo bash setup-wayland.sh
# ───────────────────────────────────────────────

set -euo pipefail

echo "🚀 Настройка Wayland на Debian 12..."

# Проверка: только Debian 12
if ! grep -q "bookworm" /etc/os-release; then
    echo "❗ Этот скрипт предназначен для Debian 12 (bookworm)"
    lsb_release -a 2>/dev/null || cat /etc/os-release
    exit 1
fi

# Проверка: запущен через sudo
if [ "$EUID" -ne 0 ]; then
    echo "❗ Запускай: sudo bash $0"
    exit 1
fi

# Проверка: GNOME установлен
if ! dpkg -l | grep -q "gnome-session\|gdm3" 2>/dev/null; then
    echo "📦 Установка GNOME (сессия + дисплей-менеджер)..."
    apt update
    apt install -y gnome-session gdm3
fi

# Проверка: Wayland-сессия доступна
if [ ! -f /usr/share/wayland-sessions/gnome.desktop ]; then
    echo "❌ Wayland-сессия не найдена. Проверь, установлен ли пакет 'gnome-session'"
    exit 1
fi

# ───────────────────────────────────────────────
# 1. Включаем Wayland в GDM
# ───────────────────────────────────────────────
echo "🔧 Включение Wayland в GDM..."
GDM_CONF="/etc/gdm3/daemon.conf"

# Создаём файл, если его нет
if [ ! -f "$GDM_CONF" ]; then
    echo "📝 Создаём $GDM_CONF..."
    touch "$GDM_CONF"
fi

# Удаляем старую строку WaylandEnable
sed -i '/^WaylandEnable/d' "$GDM_CONF" 2>/dev/null || true

# Добавляем правильную настройку
if grep -q "\[daemon\]" "$GDM_CONF"; then
    sed -i '/\[daemon\]/a WaylandEnable=true' "$GDM_CONF"
else
    echo -e "[daemon]\nWaylandEnable=true" >> "$GDM_CONF"
fi

echo "✅ Wayland включён в $GDM_CONF"

# ───────────────────────────────────────────────
# 2. Проверка графической карты (NVIDIA)
# ───────────────────────────────────────────────
echo "🔍 Проверка видеодрайвера..."
gpu=$(lspci | grep -i "vga\|3d\|display" | head -1)

echo "Видеокарта: $gpu"

if echo "$gpu" | grep -iq "nvidia"; then
    echo "⚠️  Обнаружена NVIDIA!"
    echo "❗ Проприетарные драйверы NVIDIA не поддерживают Wayland по умолчанию."
    echo "   Рекомендации:"
    echo "   1. Используй X11 (выбери 'GNOME on Xorg' на экране входа)"
    echo "   2. Или установи Wayland-среду: Sway/Hyprland"
    echo "   3. Или добавь: export __GL_YIELD='USLEEP' в ~/.profile"
    read -p "Продолжить настройку Wayland (только для nouveau/открытых драйверов)? [y/N] " -n1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "⛔ Wayland отключён из-за NVIDIA."
        sed -i 's/WaylandEnable=true/WaylandEnable=false/' "$GDM_CONF"
        echo "✅ GDM переведён обратно на X11"
        exit 0
    fi
fi

# ───────────────────────────────────────────────
# 3. Дополнительные настройки (опционально)
# ───────────────────────────────────────────────
echo "🔧 Применяем дополнительные настройки..."

# Убедимся, что gdm3 — дефолтный дисплей-менеджер
if command -v dpkg-reconfigure >/dev/null; then
    echo "gdm3 gdm3/daemon select /usr/sbin/gdm3" | debconf-set-selections
    dpkg-reconfigure -f noninteractive gdm3
fi

# ───────────────────────────────────────────────
# 4. Инструкция для пользователя
# ───────────────────────────────────────────────
cat << 'EOF'
✅ Настройка Wayland завершена!

📌 Чтобы войти в Wayland:
1. Перезагрузи систему: sudo reboot
2. На экране входа (GDM):
   - Введи имя пользователя
   - Нажми на ⚙️ (шестерёнку) в правом нижнем углу
   - Выбери: **"GNOME"** (не "GNOME on Xorg")

✅ Проверить сессию:
    echo $XDG_SESSION_TYPE
    → Должно быть: wayland

💡 Если Wayland не запускается:
- Причина: NVIDIA, Secure Boot, или старый драйвер
- Решение: используй X11 или установи Sway

🚀 Хочешь чистый Wayland-менеджер (Sway/Hyprland)? Напиши — скину скрипт!
EOF

# ───────────────────────────────────────────────
# 5. Завершение
# ───────────────────────────────────────────────
echo ""
echo "💡 Скрипт выполнен. Wayland активирован в GDM."
echo "🔥 Ты на шаг ближе к современному Linux."

exit 0