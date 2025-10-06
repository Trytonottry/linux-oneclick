#!/bin/bash

echo "🔧 Исправление конфигурации Rofi (устаревший синтаксис theme)..."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
ROFI_THEME_DIR="$HOME/.local/share/rofi/themes"

mkdir -p "$(dirname "$ROFI_CONFIG")"
mkdir -p "$ROFI_THEME_DIR"

# --- 1. Проверяем, использует ли конфиг старый синтаксис ---
if [ -f "$ROFI_CONFIG" ] && grep -q "theme:" "$ROFI_CONFIG" && ! grep -q "@theme" "$ROFI_CONFIG"; then
    echo "🔄 Обнаружен устаревший синтаксис. Обновляем конфиг..."

    # Сохраняем шрифт, если был задан
    FONT_LINE=""
    if grep -q "font:" "$ROFI_CONFIG"; then
        FONT_LINE=$(grep "font:" "$ROFI_CONFIG" | head -n1)
    else
        FONT_LINE='font: "Inter 12";'
    fi

    # Создаём новый конфиг
    cat > "$ROFI_CONFIG" << EOF
/* Rofi config — современный синтаксис */
configuration {
    $FONT_LINE
    show-icons: true;
    icon-theme: "Papirus-Dark";
    dpi: 96;
}

/* Подключаем тему */
@theme "gruvbox-dark"
EOF

    print_status "Конфиг Rofi обновлён до нового синтаксиса."
else
    print_status "Конфиг Rofi уже в актуальном формате."
fi

# --- 2. Устанавливаем тему gruvbox-dark, если её нет ---
THEME_FILE="$ROFI_THEME_DIR/gruvbox-dark.rasi"
if [ ! -f "$THEME_FILE" ]; then
    echo "📥 Устанавливаем тему 'gruvbox-dark' для Rofi..."
    curl -fsSL https://raw.githubusercontent.com/davatorium/rofi-themes-collection/master/themes/gruvbox-dark.rasi -o "$THEME_FILE"
    print_status "Тема 'gruvbox-dark' установлена."
else
    print_status "Тема 'gruvbox-dark' уже установлена."
fi

# --- 3. Проверка: запустим Rofi в режиме теста ---
echo "🧪 Тестируем запуск Rofi..."
timeout 3 rofi -show drun -theme gruvbox-dark &

sleep 2

if pgrep -x "rofi" > /dev/null; then
    pkill rofi
    print_status "Rofi запускается без ошибок!"
else
    print_warning "Rofi не запустился — проверь вручную: rofi -show drun"
fi

echo ""
print_status "Готово! Ошибки конфигурации устранены."