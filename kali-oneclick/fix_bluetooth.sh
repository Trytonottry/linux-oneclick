#!/bin/bash
set -e

echo "🔧 Исправление Bluetooth для ноутбуков Acer (Kali/Ubuntu/Debian)"
echo "---------------------------------------------------------------"

# Проверка наличия Bluetooth устройств
echo "🔍 Проверяем, видит ли система адаптер..."
lsusb | grep -i bluetooth || echo "❌ Bluetooth-устройство не найдено через USB"
lspci | grep -i network || true

# Разблокировка через rfkill
echo "🧹 Разблокировка Bluetooth..."
sudo rfkill unblock all || true

# Установка нужных пакетов
echo "📦 Установка драйверов и прошивок..."
sudo apt update
sudo apt install -y bluez blueman rfkill \
    firmware-linux-nonfree firmware-iwlwifi \
    firmware-realtek firmware-atheros \
    intel-bluetooth-firmware || true

# Перезагрузка модулей ядра
echo "♻️ Перезапуск модулей ядра..."
sudo modprobe -r btusb || true
sudo modprobe btusb

# Перезапуск сервиса Bluetooth
echo "🔄 Перезапуск службы Bluetooth..."
sudo systemctl enable bluetooth --now
sudo systemctl restart bluetooth

# Проверка статуса
echo "📡 Проверка состояния:"
sudo systemctl status bluetooth | grep Active
rfkill list
hciconfig -a | grep -E "hci|BD Address" || echo "❌ Bluetooth интерфейс не найден"

echo "---------------------------------------------------------------"
echo "✅ Попробуй теперь выполнить:"
echo "   bluetoothctl"
echo "   power on"
echo "   scan on"
echo "---------------------------------------------------------------"
echo "💡 Если Bluetooth всё ещё не работает:"
echo "   - Проверь BIOS: включен ли Wireless/Bluetooth"
echo "   - Перезагрузи систему и повтори запуск скрипта"
echo "---------------------------------------------------------------"
