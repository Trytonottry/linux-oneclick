#!/bin/bash

# ======================================================================
# 🎯 XUBUNTU MASTER SETUP SCRIPT — ONE CLICK TO RULE THEM ALL
# ======================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$PROJECT_DIR/setup.log"
PC_MODE=true  # если false — включает ноутбучные фичи (например, Wi-Fi fix)

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функции
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_step() {
    echo -e "${BLUE}▶️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

run_script() {
    local script="$1"
    if [ -f "$script" ]; then
        print_step "Запуск: $(basename "$script")"
        log "Запуск $script"
        bash "$script" 2>&1 | tee -a "$LOG_FILE"
        if [ $? -eq 0 ]; then
            print_success "$(basename "$script") успешно выполнен."
            log "$(basename "$script") — OK"
        else
            print_error "$(basename "$script") завершился с ошибкой!"
            log "$(basename "$script") — FAILED"
        fi
    else
        print_warning "Скрипт не найден: $(basename "$script")) — пропускаем."
        log "$(basename "$script") — NOT FOUND"
    fi
    echo ""
}

# --- Начало ---
echo ""
echo -e "${GREEN}🚀 XUBUNTU MASTER SETUP — ONE CLICK INSTALL${NC}"
echo -e "${YELLOW}Автоматическая настройка всей системы. Поехали!${NC}"
echo ""

# Создаём лог-файл
echo "=== Начало установки: $(date) ===" > "$LOG_FILE"

# --- Порядок выполнения скриптов ---
SCRIPTS=(
    "update_system_snap_flatpak.sh"     # 1. Сначала обновляем систему
    "beautify_xubuntu_desktop.sh"       # 2. Красивый интерфейс
    "setup_kitty_omz.sh"                # 3. Терминал + ZSH
    "install_dev_tools.sh"              # 4. Dev-инструменты
    "install_apps.sh"                   # 5. Приложения
    "setup_gui_comfort.sh"              # 6. Доп. комфорт GUI
    "setup_auto_backup.sh"              # 7. Бэкапы
    "cleanup_system.sh"                 # 8. Очистка
)

# Добавляем fix_wifi_suspend.sh только если PC_MODE=false
if [ "$PC_MODE" = false ]; then
    SCRIPTS+=("fix_wifi_suspend.sh")
fi

# --- Запускаем каждый скрипт ---
for script in "${SCRIPTS[@]}"; do
    run_script "$PROJECT_DIR/$script"
done

# --- Финал ---
echo ""
echo -e "${GREEN}🎉 ВСЕ СКРИПТЫ ВЫПОЛНЕНЫ!${NC}"
echo -e "${YELLOW}Рекомендуется перезагрузить систему для полного применения всех настроек:${NC}"
echo "   sudo reboot"
echo ""
echo -e "${BLUE}Лог установки сохранён: $LOG_FILE${NC}"
echo ""

log "=== Установка завершена: $(date) ==="