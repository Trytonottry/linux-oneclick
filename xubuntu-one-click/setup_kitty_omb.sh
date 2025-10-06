#!/bin/bash

echo "🚀 Начинаем настройку Kitty + Oh My Bash + Fish-style автодополнения..."

# Установка Kitty (если не установлен)
if ! command -v kitty &> /dev/null; then
    echo "📦 Устанавливаем Kitty..."
    sudo apt update && sudo apt install -y kitty
fi

# Установка Oh My Bash
if [ ! -d "$HOME/.oh-my-bash" ]; then
    echo "📦 Устанавливаем Oh My Bash..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
else
    echo "✅ Oh My Bash уже установлен."
fi

# Установка bash-completion и настройка fish-style автодополнения
echo "🔧 Настраиваем fish-style автодополнение в bash..."

# Устанавливаем bash-completion, если не установлен
sudo apt install -y bash-completion

# Добавляем настройки в ~/.bashrc (если ещё не добавлены)
if ! grep -q "fish-like completion" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# >>> fish-like completion >>>
# Включаем автодополнение по Tab (как в fish)
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'TAB:menu-complete'
# <<< fish-like completion <<<

EOF
    echo "✅ Fish-style автодополнение добавлено в ~/.bashrc"
fi

# Перезагружаем конфигурацию bash
source ~/.bashrc

# Создаем красивый конфиг для Kitty (если нет)
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
mkdir -p "$(dirname "$KITTY_CONF")"

if [ ! -f "$KITTY_CONF" ]; then
    echo "🎨 Создаем красивый конфиг Kitty..."
    cat > "$KITTY_CONF" << 'EOF'
# Kitty config — Modern & Clean
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12.0

# Цветовая схема (Dracula)
background #282a36
foreground #f8f8f2
cursor     #f8f8f0

# Цвета ANSI
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

# Поведение
confirm_os_window_close 0
tab_bar_style            powerline
tab_title_template       {title}
scrollback_lines         10000
wheel_scroll_multiplier  5.0

# Горячие клавиши
map ctrl+shift+t new_tab
map ctrl+shift+w close_tab
map ctrl+tab     next_tab
map ctrl+shift+tab prev_tab
EOF
    echo "✅ Конфиг Kitty создан: $KITTY_CONF"
else
    echo "✅ Конфиг Kitty уже существует."
fi

# Установка шрифта JetBrainsMono Nerd Font (опционально, но рекомендуется)
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if [ ! -f "$FONT_DIR/JetBrainsMono-Regular-Nerd-Font-Complete.ttf" ]; then
    echo "📥 Скачиваем JetBrainsMono Nerd Font..."
    wget -qO- https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip | zcat > /tmp/jetbrains.zip
    unzip -p /tmp/jetbrains.zip "JetBrains Mono*/Regular/JetBrainsMonoNerdFont-Regular.ttf" > "$FONT_DIR/JetBrainsMono-Regular-Nerd-Font-Complete.ttf"
    fc-cache -fv > /dev/null
    rm -f /tmp/jetbrains.zip
    echo "✅ Шрифт установлен. Перезапустите Kitty для применения."
fi

echo "🎉 Всё готово! Перезапустите терминал или выполните:"
echo "   exec bash"
echo "   kitty"