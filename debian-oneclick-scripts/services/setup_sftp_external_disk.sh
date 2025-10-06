#!/bin/bash

# Проверка на root
if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт должен запускаться с правами root."
    echo "Используй: sudo $0"
    exec sudo "$0" "$@"
    exit $?
fi

# Проверка и установка zenity (GUI)
if ! command -v zenity &> /dev/null; then
    apt update && apt install -y zenity
fi

USE_GUI=true
if ! zenity --version &> /dev/null; then
    USE_GUI=false
    echo "GUI не доступен. Работаем в терминале."
    read -n1 -r -p "Нажмите Enter для продолжения..." key
fi

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_msg() {
    if $USE_GUI; then
        zenity --info --text="$1" --title="SFTP Setup"
    else
        echo -e "${GREEN}$1${NC}"
        read -n1 -r -p "Нажмите Enter для продолжения..." key
    fi
}

ask_yesno() {
    if $USE_GUI; then
        zenity --question --text="$1" --ok-label="Да" --cancel-label="Нет"
        return $?
    else
        while true; do
            read -p "$1 (y/N): " yn
            case $yn in
                [Yy]*) return 0 ;;
                [Nn]*|"") return 1 ;;
                *) echo "Введите y или n" ;;
            esac
        done
    fi
}

input_text() {
    if $USE_GUI; then
        zenity --entry --text="$1" --title="Ввод"
    else
        read -p "$1: " input_var
        echo "$input_var"
    fi
}

# === Начало ===
if $USE_GUI; then
    zenity --info --text="Добро пожаловать в мастер настройки SFTP для внешнего диска!" --title="SFTP Setup"
fi

echo -e "${YELLOW}=== Настройка SFTP с доступом ко внешнему диску ===${NC}"

# --- Шаг 1: Путь к монтированию ---
MOUNT_POINT=$(input_text "Введите точку монтирования (по умолчанию: /mnt/external)")
MOUNT_POINT="${MOUNT_POINT:-/mnt/external}"

sudo mkdir -p "$MOUNT_POINT"

# --- Шаг 2: UUID или устройство ---
if $USE_GUI; then
    DEVICE=$(zenity --entry --text="Введите UUID диска (например: abcd-1234) или путь (например: /dev/sdb1). Оставьте пустым, чтобы показать список дисков." --title="Устройство")
else
    echo "Список дисков:"
    lsblk -f | grep -E "(ext|ntfs|vfat|fuseblk)"
    echo
    read -p "Введите UUID или путь устройства (например: /dev/sdb1): " DEVICE
fi

if [[ -z "$DEVICE" ]]; then
    echo "Список блочных устройств:"
    lsblk -f
    if $USE_GUI; then
        DEVICE=$(zenity --entry --text="Введите путь устройства (например: /dev/sdb1):" --title="Устройство")
    else
        read -p "Введите путь устройства: " DEVICE
    fi
fi

# Проверим, это UUID или путь
if [[ "$DEVICE" == UUID=* ]]; then
    DEVICE_PATH=$(findmnt -n -o SOURCE -T "$MOUNT_POINT" 2>/dev/null || echo "/dev/disk/by-uuid/${DEVICE#UUID=}")
else
    DEVICE_PATH="$DEVICE"
fi

# --- Шаг 3: Файловая система ---
if $USE_GUI; then
    FS_TYPE=$(zenity --list --text="Выберите тип файловой системы:" --radiolist \
        --column="Выбор" --column="Тип" \
        TRUE "ext4" \
        FALSE "ntfs" \
        FALSE "vfat")
else
    echo "Выберите тип ФС:"
    echo "1) ext4 (Linux)"
    echo "2) ntfs (Windows)"
    echo "3) vfat (FAT32)"
    read -p "Выберите (1-3): " fs_choice
    case $fs_choice in
        2) FS_TYPE="ntfs" ;;
        3) FS_TYPE="vfat" ;;
        *) FS_TYPE="ext4" ;;
    esac
fi

# --- Шаг 4: Монтирование ---
echo -e "${GREEN}🔄 Монтируем диск...${NC}"
mount "$DEVICE_PATH" "$MOUNT_POINT" 2>/dev/null || {
    case "$FS_TYPE" in
        "ntfs")
            apt install -y ntfs-3g
            mount -t ntfs-3g "$DEVICE_PATH" "$MOUNT_POINT"
            ;;
        "vfat")
            mount -t vfat "$DEVICE_PATH" "$MOUNT_POINT"
            ;;
        *)
            mount -t ext4 "$DEVICE_PATH" "$MOUNT_POINT"
            ;;
    esac
}

if ! mountpoint -q "$MOUNT_POINT"; then
    echo -e "${RED}❌ Не удалось смонтировать диск.${NC}"
    exit 1
fi

show_msg "✅ Диск успешно смонтирован в $MOUNT_POINT"

# --- Шаг 5: Имя пользователя ---
SFTP_USER=$(input_text "Введите имя SFTP-пользователя (по умолчанию: sftpuser)")
SFTP_USER="${SFTP_USER:-sftpuser}"

# --- Шаг 6: Создание пользователя ---
if id "$SFTP_USER" &>/dev/null; then
    show_msg "Пользователь $SFTP_USER уже существует."
else
    useradd -s /usr/sbin/nologin -m "$SFTP_USER"
    show_msg "Пользователь $SFTP_USER создан."
fi

# --- Шаг 7: Установка пароля ---
if $USE_GUI; then
    while true; do
        PASS1=$(zenity --password --title="Пароль" --text="Введите пароль для $SFTP_USER:")
        PASS2=$(zenity --password --title="Подтверждение" --text="Повторите пароль:")
        if [[ "$PASS1" == "$PASS2" ]]; then
            echo "$SFTP_USER:$PASS1" | chpasswd
            break
        else
            zenity --error --text="Пароли не совпадают."
        fi
    done
else
    echo "Установите пароль для $SFTP_USER:"
    passwd "$SFTP_USER"
fi

# --- Шаг 8: Группа sftpusers ---
SFTP_GROUP="sftpusers"
if ! getent group "$SFTP_GROUP" > /dev/null 2>&1; then
    groupadd "$SFTP_GROUP"
fi
usermod -aG "$SFTP_GROUP" "$SFTP_USER"

# --- Шаг 9: Права на диск ---
chown root:"$SFTP_GROUP" "$MOUNT_POINT"
chmod 755 "$MOUNT_POINT"

# Разрешить запись во все папки
chgrp -R "$SFTP_GROUP" "$MOUNT_POINT"
chmod -R 775 "$MOUNT_POINT"

show_msg "✅ Права на диск настроены. Пользователь имеет полный доступ."

# --- Шаг 10: Настройка SSH ---
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_CONFIG="/etc/ssh/sshd_config.bak.sftp.$(date +%s)"
cp "$SSHD_CONFIG" "$BACKUP_CONFIG"

# Удаляем старую секцию
sed -i '/# === SFTP External Disk ===/,/# === End SFTP ===/d' "$SSHD_CONFIG"

# Добавляем конфиг
cat >> "$SSHD_CONFIG" << EOF

# === SFTP External Disk ===
Match Group $SFTP_GROUP
    ChrootDirectory $MOUNT_POINT
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
    PermitTunnel no
# === End SFTP ===
EOF

show_msg "✅ Конфигурация SSH добавлена."

# --- Шаг 11: fstab ---
if ! grep -q "$MOUNT_POINT" /etc/fstab; then
    case 