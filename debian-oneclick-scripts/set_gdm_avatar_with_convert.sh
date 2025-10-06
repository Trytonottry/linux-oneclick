#!/bin/bash

AVATAR_JPEG="/home/moriarty/Pictures/moriarty.png"

# Устанавливаем imagemagick
if ! command -v convert &> /dev/null; then
    echo "📦 Устанавливаем ImageMagick для конвертации..."
    sudo apt install -y imagemagick
fi

# Проверяем тип файла
if file "$AVATAR_JPEG" | grep -q "JPEG"; then
    echo "🔄 Конвертируем JPEG в PNG..."
    convert "$AVATAR_JPEG" "$AVATAR_JPEG"
fi

# Убеждаемся, что теперь это PNG
if ! file "$AVATAR_JPEG" | grep -q "PNG"; then
    echo "❌ Не удалось конвертировать в PNG!"
    exit 1
fi

echo "✅ Файл теперь в формате PNG."

# Копируем в системную папку
sudo mkdir -p /var/lib/AccountsService/icons
sudo cp "$AVATAR_JPEG" /var/lib/AccountsService/icons/moriarty
sudo chown root:root /var/lib/AccountsService/icons/moriarty
sudo chmod 644 /var/lib/AccountsService/icons/moriarty

# Перезапускаем
sudo systemctl restart accounts-daemon gdm3

echo "🎉 Аватарка установлена! Перезагрузка не обязательна, но может помочь."