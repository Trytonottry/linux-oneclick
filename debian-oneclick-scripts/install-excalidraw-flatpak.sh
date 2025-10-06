#!/bin/bash

set -e

APP_ID="com.excalidraw.Excalidraw"
APP_NAME="Excalidraw"

echo "🔹 Проверяем наличие Flatpak..."

# Устанавливаем flatpak, если не установлен
if ! command -v flatpak &> /dev/null; then
    echo "📦 Flatpak не найден. Устанавливаем..."
    sudo apt update
    sudo apt install -y flatpak
fi

# Добавляем Flathub (если ещё не добавлен)
if ! flatpak remote-list | grep -q flathub; then
    echo "🔗 Добавляем репозиторий Flathub..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Устанавливаем Excalidraw
echo "📥 Устанавливаем $APP_NAME из Flathub..."
flatpak install -y flathub "$APP_ID"

# Интеграция с системой (ярлык в меню)
echo "🖥️ Интегрируем с окружением рабочего стола..."
flatpak override --user --filesystem=host "$APP_ID"  # опционально: доступ ко всей домашней папке

echo ""
echo "✅ $APP_NAME успешно установлен через Flatpak!"
echo "👉 Запустите из меню приложений или командой:"
echo "   flatpak run $APP_ID"
echo ""
echo "🔄 Чтобы обновить в будущем: flatpak update"
