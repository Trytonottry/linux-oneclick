#!/bin/bash

set -euo pipefail

SCRIPT_NAME="zt-diagnose.sh"
INSTALL_PATH="/usr/local/bin/diagnose"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Проверка: запущен ли от root (для копирования в /usr/local/bin)
if [ "$EUID" -ne 0 ]; then
    warn "Скрипт лучше запускать через sudo для установки в систему."
    warn "Если вы не хотите использовать sudo, установите вручную в ~/bin и добавьте в PATH."
    read -p "Продолжить без sudo? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    INSTALL_PATH="$HOME/.local/bin/diagnose"
    mkdir -p "$HOME/.local/bin"
fi

# Проверка наличия основного скрипта
if [ ! -f "$SCRIPT_NAME" ]; then
    error "Файл $SCRIPT_NAME не найден в текущей директории!"
fi

# Проверка зависимостей
log "Проверка зависимостей..."

# jq
if ! command -v jq &> /dev/null; then
    error "Требуется 'jq'. Установите: sudo apt install jq (Debian/Ubuntu) или brew install jq (macOS)"
fi

# zerotier-cli
if ! command -v zerotier-cli &> /dev/null; then
    error "Требуется 'zerotier-cli'. Убедитесь, что установлен ZeroTier One."
fi

log "Все зависимости установлены."

# Установка
log "Установка скрипта в $INSTALL_PATH..."
cp "$SCRIPT_NAME" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

log "Установка завершена!"

# Проверка
if command -v diagnose &> /dev/null; then
    log "Команда 'diagnose' доступна. Пример использования:"
    echo "  diagnose <network_id> [target_ip]"
else
    warn "Команда 'diagnose' не найдена в PATH."
    warn "Убедитесь, что $(dirname "$INSTALL_PATH") есть в вашем PATH."
    echo "Текущий PATH: $PATH"
fi
