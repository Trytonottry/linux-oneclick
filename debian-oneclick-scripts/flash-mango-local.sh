#!/bin/bash

set -e

# === Настройки ===
USER_NAME="mango"
USER_PASS="mango12"
LOCAL_IMAGE=""  # будет задан через аргумент или интерактивно
SD_CARD=""

# === Проверка ОС ===
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MAC=true
else
    IS_MAC=false
fi

# === Спросить путь к образу ===
if [[ -n "$1" ]]; then
    LOCAL_IMAGE="$1"
else
    read -p "Введите путь к .img или .img.xz файлу: " LOCAL_IMAGE
fi

if [[ ! -f "$LOCAL_IMAGE" ]]; then
    echo "❌ Ошибка: файл '$LOCAL_IMAGE' не найден!"
    exit 1
fi

# === Спросить устройство SD-карты ===
echo "Подключите SD-карту через адаптер."
echo "Текущие диски:"
if $IS_MAC; then
    diskutil list
    read -p "Введите устройство (например, /dev/disk2): " SD_CARD
    RAW_DEVICE="/dev/rdisk$(echo $SD_CARD | sed 's/\/dev\/disk//')"
else
    lsblk
    read -p "Введите устройство (например, /dev/sdb): " SD_CARD
    RAW_DEVICE="$SD_CARD"
fi

if [[ ! -e "$SD_CARD" ]]; then
    echo "❌ Ошибка: устройство $SD_CARD не найдено!"
    exit 1
fi

echo "Будет использовано: $SD_CARD"
read -p "ВСЁ НА ЭТОМ ДИСКЕ БУДЕТ УНИЧТОЖЕНО! Продолжить? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# === Установить зависимости (Linux) ===
if ! $IS_MAC; then
    if ! command -v mkpasswd >/dev/null; then
        echo "Устанавливаю mkpasswd (пакет whois)..."
        sudo apt update && sudo apt install -y whois
    fi
fi

# === Распаковать, если .xz ===
if [[ "$LOCAL_IMAGE" == *.xz ]]; then
    echo "Распаковываем .xz архив..."
    UNCOMPRESSED_IMAGE="${LOCAL_IMAGE%.xz}"
    if [[ ! -f "$UNCOMPRESSED_IMAGE" ]]; then
        xz -d -k "$LOCAL_IMAGE"
    fi
    IMAGE_TO_FLASH="$UNCOMPRESSED_IMAGE"
else
    IMAGE_TO_FLASH="$LOCAL_IMAGE"
fi

# === Записать образ ===
echo "Записываю образ на $SD_CARD... (может занять 5–15 минут)"
if $IS_MAC; then
    sudo dd if="$IMAGE_TO_FLASH" of="$RAW_DEVICE" bs=1m
else
    sudo dd if="$IMAGE_TO_FLASH" of="$RAW_DEVICE" bs=4M status=progress conv=fsync
fi
sync

# === Смонтировать boot-раздел ===
echo "Монтирую boot-раздел..."
MNT_BOOT=$(mktemp -d)

if $IS_MAC; then
    BOOT_PART="${SD_CARD}s1"
    sudo mkdir -p "$MNT_BOOT"
    sudo mount -t msdos "$BOOT_PART" "$MNT_BOOT"
else
    BOOT_PART="${SD_CARD}1"
    sudo mkdir -p "$MNT_BOOT"
    sudo mount "$BOOT_PART" "$MNT_BOOT"
fi

# === Создать ssh и userconf.txt ===
echo "Настраиваю SSH и пользователя..."

# Включить SSH
sudo touch "$MNT_BOOT/ssh"

# Сгенерировать хеш пароля
if command -v mkpasswd >/dev/null; then
    PASS_HASH=$(mkpasswd -m sha-512 "$USER_PASS")
elif command -v openssl >/dev/null; then
    SALT=$(openssl rand -base64 6 | tr -d '=')
    PASS_HASH=$(openssl passwd -6 -salt "$SALT" "$USER_PASS")
else
    echo "❌ Не удалось сгенерировать хеш пароля. Установите 'whois' (mkpasswd)."
    sudo umount "$MNT_BOOT"
    rmdir "$MNT_BOOT"
    exit 1
fi

# Записать userconf.txt
echo "$USER_NAME:$PASS_HASH" | sudo tee "$MNT_BOOT/userconf.txt" > /dev/null

# === Отмонтировать ===
sudo umount "$MNT_BOOT"
rmdir "$MNT_BOOT"

echo
echo "✅ УСПЕХ! SD-карта готова."
echo "Пользователь: $USER_NAME"
echo "Пароль:     $USER_PASS"
echo
echo "1. Вставьте SD-карту в Mango Pi"
echo "2. Подключите к Ethernet"
echo "3. Включите питание (5V/3A!)"
echo "4. Через 1–2 минуты подключайтесь:"
echo "   ssh $USER_NAME@<IP_адрес_Mango_Pi>"
