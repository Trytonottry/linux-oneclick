#!/bin/bash

# Скрипт для полного обновления Debian 12 + snapd + flatpak
# Запускать с правами root или через sudo

echo "🚀 Начинаем обновление системы Debian 12..."

# Обновление списка пакетов APT
apt update && echo "✅ Список пакетов APT обновлён"

# Обновление установленных пакетов APT
apt upgrade -y && echo "✅ Пакеты APT обновлены"

# Обновление snapd и установленных snap-пакетов
if command -v snap &> /dev/null; then
    echo "🔄 Обновляем snapd и snap-пакеты..."
    snap refresh && echo "✅ Snap-пакеты обновлены"
else
    echo "⚠️ snapd не установлен. Пропускаем обновление snap."
fi

# Обновление flatpak и установленных flatpak-приложений
if command -v flatpak &> /dev/null; then
    echo "🔄 Обновляем flatpak и приложения..."
    flatpak update -y && echo "✅ Flatpak-приложения обновлены"
else
    echo "⚠️ flatpak не установлен. Пропускаем обновление flatpak."
fi

# Очистка кэша (опционально)
echo "🧹 Очищаем кэш APT..."
apt autoremove -y
apt autoclean -y

echo "🎉 Обновление завершено!"