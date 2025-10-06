#!/bin/bash

echo "🔧 Исправление EspoCRM 404 ошибки..."

# --- 1. Проверим, где лежат файлы ---
if [ -f "/var/www/html/EspoCRM/index.php" ]; then
    echo "📁 Файлы EspoCRM найдены в /var/www/html/EspoCRM"
    
    # --- 2. Сделаем символическую ссылку в корень (проще всего) ---
    sudo ln -sf /var/www/html/EspoCRM /var/www/html/espocrm
    
    echo "🔗 Создана ссылка: /var/www/html/espocrm → EspoCRM"
    
elif [ -f "/var/www/html/index.php" ] && grep -q "EspoCRM" /var/www/html/index.php; then
    echo "✅ EspoCRM уже в корне — 404 по другой причине."
else
    echo "❌ Файлы EspoCRM не найдены. Перезапустим установку..."
    exit 1
fi

# --- 3. Проверим .htaccess ---
if [ ! -f "/var/www/html/EspoCRM/.htaccess" ]; then
    echo "📥 Восстанавливаем .htaccess..."
    sudo wget -q https://raw.githubusercontent.com/espocrm/espocrm/master/.htaccess -O /var/www/html/EspoCRM/.htaccess
fi

# --- 4. Права доступа ---
sudo chown -R www-data:www-data /var/www/html/EspoCRM
sudo chmod -R 755 /var/www/html/EspoCRM
sudo chmod -R 775 /var/www/html/EspoCRM/data /var/www/html/EspoCRM/custom

# --- 5. Перезагрузим Apache ---
sudo systemctl reload apache2

echo ""
echo "✅ Готово! Попробуй открыть:"
echo "   http://espocrm.local"
echo ""
echo "💡 Если всё ещё 404 — проверь:"
echo "   curl -H 'Host: espocrm.local' http://127.0.0.1"