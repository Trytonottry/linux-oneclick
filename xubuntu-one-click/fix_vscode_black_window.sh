#!/bin/bash

echo "🔧 Исправление чёрного окна VS Code в Xubuntu..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# --- 1. Убедимся, что мы в X11, а не Wayland ---
if [ "$XDG_SESSION_TYPE" != "x11" ]; then
    print_warning "Ты используешь Wayland! VS Code лучше работает под X11."
    echo "💡 Войди в сеанс 'Xubuntu on Xorg' (выбери при входе)."
fi

# --- 2. Установим недостающие GPU-библиотеки ---
echo "📦 Устанавливаем критические библиотеки для GPU..."
sudo apt install -y \
    libxshmfence1 \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    mesa-utils \
    libxrandr2 \
    libxcomposite1

print_status "GPU-библиотеки установлены."

# --- 3. Запускаем VS Code с отключённым GPU-ускорением (тест) ---
echo "🧪 Тестируем запуск с отключённым аппаратным ускорением..."
code --disable-gpu --disable-software-rasterizer --no-sandbox &

# Ждём 3 секунды
sleep 3

# Проверяем, запустился ли процесс
if pgrep -x "code" > /dev/null; then
    print_status "VS Code запустился с --disable-gpu — проблема в GPU-ускорении."
    echo "🛠️  Навсегда отключаем GPU для VS Code..."
    
    # Создаём обёртку-скрипт
    WRAPPER="/usr/local/bin/code"
    sudo tee "$WRAPPER" > /dev/null << 'EOF'
#!/bin/bash
exec /usr/share/code/code --disable-gpu --disable-software-rasterizer --no-sandbox "$@"
EOF
    sudo chmod +x "$WRAPPER"
    
    print_status "Создана обёртка: /usr/local/bin/code (с отключённым GPU)."
else
    print_warning "Даже с --disable-gpu не запускается. Пробуем очистить кэш..."
fi

# --- 4. Очищаем кэш VS Code (если зависает) ---
if pgrep -x "code" > /dev/null; then
    pkill -f "code"
    sleep 2
fi

echo "🧹 Очищаем кэш VS Code..."
rm -rf "$HOME/.config/Code/Cache" \
       "$HOME/.config/Code/CachedData" \
       "$HOME/.config/Code/CachedExtensions" \
       "$HOME/.config/Code/GPUCache" 2>/dev/null

print_status "Кэш VS Code очищен."

# --- 5. Финальный запуск ---
echo "🚀 Запускаем VS Code..."
code &

# --- 6. Советы ---
echo ""
echo -e "${GREEN}💡 Советы по устранению чёрного окна:${NC}"
echo " • Если проблема осталась — всегда запускай через обёртку (она уже создана)."
echo " • Убедись, что у тебя установлены драйверы GPU (nvidia-driver или mesa)."
echo " • Не используй Wayland — выбирай 'Xubuntu on Xorg' при входе в систему."
echo " • Обнови систему: sudo apt update && sudo apt upgrade"
echo ""
print_status "Готово! VS Code должен работать без чёрного экрана."