#!/bin/bash

AVATAR="$1"

if [ -z "$AVATAR" ]; then
    echo "Использование: $0 /путь/к/аватарке.jpg"
    exit 1
fi

if [ ! -f "$AVATAR" ]; then
    echo "Файл не найден: $AVATAR"
    exit 1
fi

# Определяем дисплейный менеджер
DM=$(basename "$(cat /etc/X11/default-display-manager 2>/dev/null)")

case "$DM" in
    lightdm|lxdm)
        cp "$AVATAR" ~/.face
        chmod 644 ~/.face
        echo "✅ Аватарка установлена для LightDM/LXDM"
        sudo systemctl try-restart lightdm lxdm
        ;;
    gdm3)
        sudo mkdir -p /var/lib/AccountsService/icons
        sudo cp "$AVATAR" "/var/lib/AccountsService/icons/$USER"
        sudo chmod 644 "/var/lib/AccountsService/icons/$USER"
        echo "✅ Аватарка установлена для GDM"
        sudo systemctl restart gdm3
        ;;
    sddm)
        # Конвертируем в PNG, если нужно
        if [[ "$AVATAR" == *.jpg ]] || [[ "$AVATAR" == *.jpeg ]]; then
            convert "$AVATAR" ~/.face
        else
            cp "$AVATAR" ~/.face
        fi
        chmod 644 ~/.face
        echo "✅ Аватарка установлена для SDDM (только PNG)"
        sudo systemctl restart sddm
        ;;
    *)
        echo "⚠️  Неизвестный дисплейный менеджер: $DM"
        echo "Попробуй вручную: скопируй фото как ~/.face"
        cp "$AVATAR" ~/.face
        chmod 644 ~/.face
        ;;
esac