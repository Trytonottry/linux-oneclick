#!/bin/bash

set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    if [ "$2" == "ok" ]; then
        echo -e "${GREEN}[OK]${NC} $1"
    elif [ "$2" == "warn" ]; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    else
        echo -e "${RED}[FAIL]${NC} $1"
    fi
}

die() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Проверка аргументов
if [ $# -lt 1 ]; then
    echo "Использование: $0 <network_id> [target_ip_for_ping]"
    echo "Пример: $0 abcdef1234567890 10.147.20.1"
    exit 1
fi

NETWORK_ID="$1"
TARGET_IP="${2:-}"

# 1. Проверка: запущен ли zerotier-one
if ! systemctl is-active --quiet zerotier-one 2>/dev/null; then
    if ! pgrep -x "zerotier-one" > /dev/null; then
        print_status "Сервис zerotier-one не запущен." "fail"
        echo "Попробуйте: sudo systemctl start zerotier-one"
        exit 1
    fi
fi
print_status "Сервис zerotier-one запущен." "ok"

# 2. Проверка: присоединён ли к сети
if ! zerotier-cli listnetworks | grep -q "^${NETWORK_ID}"; then
    print_status "Узел не присоединён к сети ${NETWORK_ID}." "fail"
    echo "Присоединитесь: sudo zerotier-cli join ${NETWORK_ID}"
    exit 1
fi
print_status "Узел присоединён к сети ${NETWORK_ID}." "ok"

# 3. Получение деталей сети
NETWORK_INFO=$(zerotier-cli listnetworks -j | jq -r ".[] | select(.nwid == \"${NETWORK_ID}\")")
if [ -z "$NETWORK_INFO" ]; then
    die "Не удалось получить информацию о сети ${NETWORK_ID}."
fi

# 4. Проверка: назначен ли IP
ASSIGNED_IPS=$(echo "$NETWORK_INFO" | jq -r '.assignedAddresses[] // empty')
if [ -z "$ASSIGNED_IPS" ]; then
    print_status "IP-адрес не назначен. Возможно, узел не авторизован." "warn"
else
    print_status "Назначенные IP: $(echo "$ASSIGNED_IPS" | tr '\n' ' ')" "ok"
fi

# 5. Проверка авторизации
STATUS=$(echo "$NETWORK_INFO" | jq -r '.status')
if [ "$STATUS" != "AUTHORIZED" ]; then
    print_status "Статус: $STATUS (ожидается AUTHORIZED)." "warn"
    echo "Узел должен быть авторизован в ZeroTier Central или контроллере."
else
    print_status "Узел авторизован." "ok"
fi

# 6. Проверка peer-соединений (NAT traversal)
PEERS=$(zerotier-cli listpeers)
DIRECT_PEER=false
while IFS= read -r line; do
    if [[ $line == *"${NETWORK_ID}"* ]] && [[ $line == *"DIRECT"* ]]; then
        DIRECT_PEER=true
        break
    fi
done <<< "$PEERS"

if [ "$DIRECT_PEER" = true ]; then
    print_status "Установлено прямое (DIRECT) соединение с пиром." "ok"
else
    print_status "Соединение через ретранслятор (RELAY). Возможна задержка." "warn"
fi

# 7. Опционально: пинг целевого IP
if [ -n "$TARGET_IP" ]; then
    if ping -c 1 -W 2 "$TARGET_IP" &>/dev/null; then
        print_status "Пинг до $TARGET_IP успешен." "ok"
    else
        print_status "Не удаётся пропинговать $TARGET_IP." "warn"
        echo "Возможные причины: узел выключен, фаервол, неправильный маршрут."
    fi
fi

echo
echo -e "${GREEN}Диагностика завершена.${NC}"
