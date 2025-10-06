#!/bin/bash

echo "🔄 Начинаем полное обновление системы и проверку Snap/Flatpak..."

# Обновление системы
echo "📦 Обновляем системные пакеты..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# Проверка и установка Snapd
if ! command -v snap &> /dev/null; then
    echo "📦 Устанавливаем snapd..."
    sudo apt install -y snapd
    sudo snap install core 2>/dev/null || echo "⚠️ Snap core уже установлен или ошибка."
else
    echo "✅ Snap уже установлен. Обновляем..."
    sudo snap refresh
fi

# Проверка и установка Flatpak
if ! command -v flatpak &> /dev/null; then
    echo "📦 Устанавливаем flatpak..."
    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    echo "✅ Flatpak уже установлен. Обновляем репозитории..."
    flatpak remote-list --user | grep -q flathub || flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Обновление Flatpak-приложений (системных и пользовательских)
echo "🔄 Обновляем Flatpak приложения..."
flatpak update -y --system 2>/dev/null
flatpak update -y --user 2>/dev/null

# Информация о установленных Flatpak/Snap
echo "📊 Текущие Snap-пакеты:"
snap list 2>/dev/null || echo "Нет установленных Snap-пакетов."

echo "📊 Текущие Flatpak-пакеты:"
flatpak list --app --columns=application,version 2>/dev/null || echo "Нет установленных Flatpak-приложений."

echo "✅ Система, Snap и Flatpak обновлены!"