#!/bin/bash

echo "🚀 Запуск полной автоматической настройки Xubuntu..."

SCRIPTS=(
    "./setup_kitty_omz.sh"
    "./update_system_snap_flatpak.sh"
    "./install_dev_tools.sh"
    "./setup_gui_comfort.sh"
    "./cleanup_system.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "▶️ Запуск $script..."
        bash "$script"
    else
        echo "⚠️ Скрипт $script не найден — пропускаем."
    fi
done

echo "🎉 ПОЛНАЯ НАСТРОЙКА ЗАВЕРШЕНА! Перезагрузите систему для применения всех изменений:"
echo "   sudo reboot"