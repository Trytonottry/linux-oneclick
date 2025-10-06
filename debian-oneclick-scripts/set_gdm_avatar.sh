#!/bin/bash

# Путь к твоей аватарке
AVATAR_SOURCE="/home/moriarty/Pictures/moriarty.png"

# Проверяем, существует ли файл
if [ ! -f "$AVATAR_SOURCE" ]; then
    echo "❌ Файл аватарки не найден: $AVATAR_SOURCE"
    exit 1
fi

echo "🖼️  Устанавливаем аватарку для GDM3..."

# Копируем в системную папку AccountsService
sudo mkdir -p /var/lib/AccountsService/icons
sudo cp "$AVATAR_SOURCE" /var/lib/AccountsService/icons/moriarty

# Устанавливаем правильные права
sudo chown root:root /var/lib/AccountsService/icons/moriarty
sudo chmod 644 /var/lib/AccountsService/icons/moriarty

echo "✅ Аватарка скопирована в /var/lib/AccountsService/icons/moriarty"

# Перезапускаем сервисы
echo "🔄 Перезапускаем accounts-daemon и gdm3..."
sudo systemctl restart accounts-daemon
sudo systemctl restart gdm3

echo ""
echo "🎉 Готово! Через несколько секунд ты увидишь свою аватарку на экране входа."
echo "💡 Совет: если не появилась — перезагрузи систему."