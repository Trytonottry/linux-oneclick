#!/bin/bash

echo "💼 Установка EspoCRM — локальной CRM-системы..."

GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

# --- Требуемые зависимости ---
echo "📦 Устанавливаем LAMP-стек..."
sudo apt install -y apache2 mariadb-server php php-mysql php-curl php-json php-gd php-zip php-mbstring php-xml php-bcmath

# Запускаем службы
sudo systemctl enable apache2 mariadb
sudo systemctl start apache2 mariadb

# --- Настройка MySQL ---
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'espocrm_root';"
echo "mysql_root_password = espocrm_root" > ~/espocrm_db.conf

# --- Скачиваем EspoCRM ---
cd /tmp
wget -q https://www.espocrm.com/downloads/EspoCRM-8.0.0.zip -O espocrm.zip
sudo unzip espocrm.zip -d /var/www/html/
sudo chown -R www-data:www-data /var/www/html/EspoCRM
sudo chmod -R 755 /var/www/html/EspoCRM

# --- Настройка Apache ---
sudo bash -c 'cat > /etc/apache2/sites-available/espocrm.conf' << 'EOF'
<VirtualHost *:80>
    ServerName espocrm.local
    DocumentRoot /var/www/html/EspoCRM
    <Directory /var/www/html/EspoCRM>
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

sudo a2ensite espocrm.conf
sudo a2enmod rewrite
sudo systemctl reload apache2

# --- Добавляем в hosts ---
echo "127.0.0.1 espocrm.local" | sudo tee -a /etc/hosts

print_status "EspoCRM установлен!"
echo ""
echo "🔧 Дальнейшие шаги:"
echo "1. Открой в браузере: http://espocrm.local"
echo "2. Следуй инструкциям установщика"
echo "3. Используй данные БД:"
echo "   - Хост: localhost"
echo "   - Пользователь: root"
echo "   - Пароль: espocrm_root (сохранён в ~/espocrm_db.conf)"
echo "4. После установки удали файл конфигурации:"
echo "   rm ~/espocrm_db.conf"