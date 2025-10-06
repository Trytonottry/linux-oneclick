#!/bin/bash

# === Настройки ===
SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_KEY_PUB="$SSH_KEY.pub"

# Твои хосты: имя | пользователь | IP
declare -A HOSTS=(
    [1]="Work|host1|10.147.19.25"
    [2]="WoWe|kali|10.147.19.210"
    [3]="Orange Pi|root|10.147.19.180"
)

# === Цвета ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# === Проверка зависимостей ===
check_deps() {
    for cmd in ssh ssh-copy-id; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}❌ Не установлен: $cmd${NC}"
            exit 1
        fi
    done
}

# === Генерация SSH-ключа ===
setup_ssh_key() {
    if [[ ! -f "$SSH_KEY" ]]; then
        echo -e "${YELLOW}🔑 Генерирую SSH-ключ...${NC}"
        ssh-keygen -t ed25519 -C "zt-auto" -f "$SSH_KEY" -N ""
    else
        echo -e "${GREEN}✅ SSH-ключ уже существует.${NC}"
    fi
}

# === Подключение к хосту ===
connect_host() {
    local name="$1"
    local user="$2"
    local ip="$3"
    local target="$user@$ip"

    echo -e "${GREEN}🔌 Подключаюсь к $name ($target)...${NC}"

    # Проверяем, есть ли уже доступ без пароля
    if ssh -o ConnectTimeout=5 -o BatchMode=yes -i "$SSH_KEY" "$target" "echo 2>/dev/null" &>/dev/null; then
        echo -e "${GREEN}✅ Доступ без пароля настроен. Запускаю сессию...${NC}"
        ssh -i "$SSH_KEY" "$target"
    else
        echo -e "${YELLOW}⚠️  Ключ ещё не скопирован. Требуется однократный ввод пароля.${NC}"
        if ssh-copy-id -i "$SSH_KEY.pub" "$target"; then
            echo -e "${GREEN}✅ Ключ скопирован. Подключаюсь...${NC}"
            ssh -i "$SSH_KEY" "$target"
        else
            echo -e "${RED}❌ Не удалось скопировать ключ. Проверь доступность хоста и пароль.${NC}"
        fi
    fi
}

# === Основное меню ===
main() {
    check_deps
    setup_ssh_key

    echo -e "${GREEN}=== Меню подключения к моим устройствам ===${NC}"
    echo

    # Выводим список
    for i in "${!HOSTS[@]}"; do
        IFS='|' read -r desc user ip <<< "${HOSTS[$i]}"
        echo "$i) $desc — $user@$ip"
    done

    echo
    read -p "Выберите хост (1–3): " choice

    if [[ -z "${HOSTS[$choice]}" ]]; then
        echo -e "${RED}❌ Неверный выбор. Выход.${NC}"
        exit 1
    fi

    IFS='|' read -r desc user ip <<< "${HOSTS[$choice]}"
    connect_host "$desc" "$user" "$ip"
}

# Запуск
main "$@"
