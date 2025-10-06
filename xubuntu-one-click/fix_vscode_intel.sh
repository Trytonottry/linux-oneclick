#!/bin/bash

echo "🔧 Исправление VS Code для Intel UHD Graphics (без --disable-gpu!)..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# --- 1. Проверка: Intel GPU? ---
if ! glxinfo &> /dev/null; then
    sudo apt install -y mesa-utils
fi

if glxinfo | grep -i "Intel" > /dev/null; then
    print_status "Обнаружена Intel GPU — настраиваем VS Code правильно."
else
    print_warning "Intel GPU не обнаружена. Продолжаем с общими настройками."
fi

# --- 2. Устанавливаем актуальные Mesa-драйверы ---
echo "📦 Устанавливаем/обновляем Mesa для Intel..."
sudo apt install -y \
    libgl1 \
    mesa-vulkan-drivers \
    vulkan-intel \
    intel-media-va-driver-non-free \
    libvulkan1

print_status "Драйверы Intel обновлены."

# --- 3. Удаляем обёртку с --disable-gpu (если есть) ---
WRAPPER="/usr/local/bin/code"
if [ -f "$WRAPPER" ]; then
    echo "🗑️  Удаляем обёртку с --disable-gpu (вредна для Intel)..."
    sudo rm -f "$WRAPPER"
    print_status "Обёртка удалена. Будет использоваться оригинальный VS Code."
fi

# --- 4. Очищаем кэш VS Code ---
echo "🧹 Очищаем кэш VS Code..."
rm -rf "$HOME/.config/Code/Cache" \
       "$HOME/.config/Code/CachedData" \
       "$HOME/.config/Code/GPUCache" \
       "$HOME/.config/Code/Code Cache" 2>/dev/null

print_status "Кэш очищен."

# --- 5. Запускаем VS Code БЕЗ --disable-gpu ---
echo "🚀 Запускаем VS Code в штатном режиме (с GPU-ускорением)..."
code &

# Ждём 5 секунд
sleep 5

# Проверяем, жив ли процесс
if pgrep -x "code" > /dev/null; then
    print_status "VS Code запущен успешно!"
else
    print_warning "VS Code не запустился. Попробуй вручную: code"
fi

# --- 6. Советы ---
echo ""
echo -e "${GREEN}💡 Советы для Intel UHD:${NC}"
echo " • Никогда не используй --disable-gpu на Intel — это ломает производительность."
echo " • Убедись, что в BIOS включена интегрированная графика."
echo " • Обновляй систему: sudo apt update && sudo apt upgrade"
echo " • Если зависает — попробуй: code --disable-extensions"
echo ""
print_status "Готово! VS Code должен работать быстро и без чёрного экрана."