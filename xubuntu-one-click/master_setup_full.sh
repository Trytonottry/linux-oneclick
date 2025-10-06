#!/bin/bash

# ======================================================================
# 🎯 XUBUNTU MASTER SETUP — FINAL EDITION (ПК, Intel, без Snap, с Rofi @theme)
# ======================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$PROJECT_DIR/setup.log"
PC_MODE=true

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
echo -e "${GREEN}🚀 XUBUNTU MASTER SETUP — FINAL EDITION${NC}"
echo -e "${YELLOW}Полная настройка для ПК с Intel UHD Graphics. Поехали!${NC}"
echo ""

echo "=== Начало установки: $(date) ===" > "$LOG_FILE"

# --- Определяем GPU ---
HAS_INTEL=false
if command -v glxinfo &> /dev/null; then
    if glxinfo 2>/dev/null | grep -i "Intel" > /dev/null; then
        HAS_INTEL=true
        log "Обнаружена Intel GPU"
    fi
fi

# --- Список скриптов ---
SCRIPTS=(
    "update_system_snap_flatpak.sh"     # 1. Обновление
    "beautify_xubuntu_desktop.sh"       # 2. Внешний вид
    "setup_kitty_omz.sh"                # 3. Терминал
    "install_dev_tools.sh"              # 4. Dev-инструменты
    "install_apps.sh"                   # 5. Приложения (без Snap!)
    "install_obsidian.sh"               # 6. Obsidian (Flatpak)
    "install_hidde_vpn.sh"              # 7. Hidde VPN
    "setup_gui_comfort.sh"              # 8. Доп. комфорт
    "enable_transparency.sh"            # 9. Прозрачность + Picom
    "fix_app_icons.sh"                  # 10. Иконки (Firefox, VS Code и др.)
    "setup_auto_backup.sh"              # 11. Бэкапы
    "cleanup_system.sh"                 # 12. Очистка
)

# Для Intel — специальный фикс VS Code (без --disable-gpu)
if [ "$HAS_INTEL" = true ]; then
    SCRIPTS+=("fix_vscode_intel.sh")
else
    SCRIPTS+=("fix_vscode_black_window.sh")
fi

# --- Запускаем все скрипты ---
for script in "${SCRIPTS[@]}"; do
    run_script "$PROJECT_DIR/$script"
done

# --- Финальный фикс: Rofi (новый синтаксис @theme) ---
if command -v rofi &> /dev/null; then
    run_script "$PROJECT_DIR/fix_rofi_config.sh"
fi

# --- Финал ---
echo ""
echo -e "${GREEN}🎉 ВСЁ ГОТОВО! Xubuntu настроен под твой ПК.${NC}"
echo ""
if [ "$HAS_INTEL" = true ]; then
    echo -e "${BLUE}💡 Особенности для Intel UHD:${NC}"
    echo " • VS Code работает с GPU-ускорением (без тормозов)"
    echo " • Драйверы Mesa обновлены"
fi
echo ""
echo -e "${YELLOW}Рекомендуется перезагрузить систему:${NC}"
echo "   sudo reboot"
echo ""
echo -e "${BLUE}Лог: $LOG_FILE${NC}"
log "=== Установка завершена: $(date) ==="