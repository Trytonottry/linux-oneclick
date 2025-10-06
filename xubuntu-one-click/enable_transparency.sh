#!/bin/bash

echo "🌫️  Запуск настройки прозрачности и визуальных эффектов..."

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# --- 1. Включаем композитинг в XFCE (обязательно!) ---
echo "🎛️  Включаем композитинг в XFCE..."
xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null
xfconf-query -c xfwm4 -p /general/frame_opacity -s 100 2>/dev/null
print_status "Композитинг включён."

# --- 2. Устанавливаем Picom (современный композитор с эффектами) ---
if ! command -v picom &> /dev/null; then
    echo "📦 Устанавливаем Picom..."
    sudo apt update
    sudo apt install -y picom
fi

# --- 3. Создаём конфиг Picom с плавными эффектами ---
PICOM_CONF="$HOME/.config/picom/picom.conf"
mkdir -p "$(dirname "$PICOM_CONF")"

if [ ! -f "$PICOM_CONF" ]; then
    echo "🎨 Создаём конфиг Picom с fade-эффектами и тенями..."
    cat > "$PICOM_CONF" << 'EOF'
# Picom config — плавные эффекты для XFCE

# Включить/выключить тени
shadow = true;
no-dnd-shadow = true;
no-dock-shadow = true;
clear-shadow = true;
shadow-radius = 12;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.4;
shadow-ignore-shaped = false;

# Закруглённые углы (требует experimental-backends)
corner-radius = 8;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'",
  "class_g = 'Plank'",
  "class_g = 'xfce4-panel'"
];

# Прозрачность неактивных окон (опционально)
inactive-opacity = 0.95;
active-opacity = 1.0;
frame-opacity = 1.0;

# Fade-эффекты при открытии/закрытии
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-delta = 8;

# Исключения
fade-exclude = [
  "class_g = 'Xfce4-notifyd'",
  "class_g = 'Dunst'",
  "class_g = 'Plank'",
  "class_g = 'xfce4-panel'"
];

# Бэкенды
backend = "glx";
vsync = true;
detect-rounded-corners = true;
detect-client-opacity = true;
refresh-rate = 60;
EOF
    print_status "Конфиг Picom создан: $PICOM_CONF"
else
    print_status "Picom уже настроен."
fi

# --- 4. Добавляем Picom в автозагрузку ---
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
PICOM_DESKTOP="$AUTOSTART_DIR/picom.desktop"

if [ ! -f "$PICOM_DESKTOP" ]; then
    echo "🔁 Добавляем Picom в автозагрузку..."
    cat > "$PICOM_DESKTOP" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom Compositor
Exec=picom --experimental-backends -b
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Compositor with transparency and visual effects
EOF
    print_status "Picom добавлен в автозагрузку."
else
    print_status "Picom уже в автозагрузке."
fi

# --- 5. Настраиваем полупрозрачность Kitty ---
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
mkdir -p "$(dirname "$KITTY_CONF")"

# Если Kitty не установлен — пропускаем
if ! command -v kitty &> /dev/null; then
    print_warning "Kitty не установлен — прозрачность терминала пропущена."
else
    # Если конфиг не существует — создаём минимальный с прозрачностью
    if [ ! -f "$KITTY_CONF" ]; then
        echo "🎨 Создаём базовый полупрозрачный конфиг Kitty..."
        cat > "$KITTY_CONF" << 'EOF'
# Kitty — полупрозрачный терминал
font_family      JetBrainsMono Nerd Font
font_size        12.0
background_opacity 0.85
dynamic_background_opacity no

# Цвета (Dracula)
background #282a36
foreground #f8f8f2
cursor     #f8f8f0

color0  #000000
color8  #4d4d4d
color1  #ff5555
color9  #ff6e6e
color2  #50fa7b
color10 #69ff94
color3  #f1fa8c
color11 #ffffa5
color4  #bd93f9
color12 #d6acff
color5  #ff79c6
color13 #ff92d0
color6  #8be9fd
color14 #9aedfe
color7  #bbbbbb
color15 #ffffff
EOF
        print_status "Полупрозрачный конфиг Kitty создан."
    else
        # Проверяем, есть ли уже прозрачность
        if grep -q "background_opacity" "$KITTY_CONF"; then
            print_status "Прозрачность Kitty уже настроена."
        else
            echo "🔧 Добавляем прозрачность в существующий конфиг Kitty..."
            # Вставляем в начало файла
            sed -i '1i background_opacity 0.85\ndynamic_background_opacity no\n' "$KITTY_CONF"
            print_status "Прозрачность добавлена в Kitty."
        fi
    fi
fi

# --- 6. Перезапускаем Picom (если уже запущен) ---
if pgrep -x "picom" > /dev/null; then
    echo "🔄 Перезапускаем Picom для применения настроек..."
    pkill picom
    sleep 1
    picom --experimental-backends -b 2>/dev/null &
    print_status "Picom перезапущен."
fi

# --- 7. Финал ---
echo ""
echo -e "${GREEN}🎉 Прозрачность и визуальные эффекты успешно настроены!${NC}"
echo ""
echo "💡 Советы:"
echo " • Перезапусти Kitty — он станет полупрозрачным."
echo " • Окна будут плавно появляться/исчезать (fade)."
echo " • Тени и закруглённые углы работают благодаря Picom."
echo " • Чтобы отключить эффекты — удали $PICOM_DESKTOP и перезагрузи сеанс."
echo ""
print_status "Готово! Наслаждайся красивым и плавным интерфейсом."