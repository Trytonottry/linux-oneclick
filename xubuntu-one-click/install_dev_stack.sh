#!/bin/bash

echo "🧰 Установка полного стека для разработки..."

GREEN='\033[0;32m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

# --- Docker + Portainer ---
echo "🐳 Устанавливаем Docker..."
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
print_status "Docker установлен. Перезагрузи сеанс для применения групп."

# --- Portainer (UI для Docker) ---
docker volume create portainer_data
docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
print_status "Portainer запущен: http://localhost:9000"

# --- Базы данных ---
echo "🗃️  Устанавливаем PostgreSQL и MySQL..."
sudo apt install -y postgresql postgresql-contrib mysql-server
sudo systemctl enable postgresql mysql
print_status "PostgreSQL и MySQL установлены."

# --- DBeaver (универсальный клиент БД) ---
if ! command -v dbeaver &> /dev/null; then
    wget -q https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb -O /tmp/dbeaver.deb
    sudo apt install -y /tmp/dbeaver.deb
    rm -f /tmp/dbeaver.deb
fi
print_status "DBeaver установлен."

# --- Insomnia (альтернатива Postman) ---
if ! command -v insomnia &> /dev/null; then
    sudo apt install -y snapd
    sudo snap install insomnia
fi
print_status "Insomnia установлен."

# --- Netdata (мониторинг) ---
echo "📊 Устанавливаем Netdata..."
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait
print_status "Netdata запущен: http://localhost:19999"

print_status "Стек для разработки готов!"