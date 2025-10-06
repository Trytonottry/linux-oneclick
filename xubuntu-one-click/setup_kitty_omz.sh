#!/bin/bash

echo "🚀 Начинаем настройку Kitty + Oh My Zsh + Fish-style автодополнение..."

# Установка Kitty (если не установлен)
if ! command -v kitty &> /dev/null; then
    echo "📦 Устанавливаем Kitty..."
    sudo apt update && sudo apt install -y kitty
fi

# Установка ZSH, если не установлен
if ! command -v zsh &> /dev/null; then
    echo "📦 Устанавливаем ZSH..."
    sudo apt install -y zsh
fi

# Установка Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "📦 Устанавливаем Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "✅ Oh My Zsh уже установлен."
fi

# Установка плагина zsh-autosuggestions (как в fish)
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "📥 Устанавливаем zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

# Установка плагина zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "📥 Устанавливаем zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

# Добавляем плагины в ~/.zshrc (если ещё не добавлены)
if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
    echo "✅ Плагины добавлены в ~/.zshrc"
fi

# Установка красивой темы (например, 'powerlevel10k' — опционально, но рекомендуется)
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "🎨 Устанавливаем тему Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    echo "✅ Тема Powerlevel10k установлена. После первого запуска zsh будет мастер настройки."
fi

# Перезагружаем zsh
source ~/.zshrc

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

# Ставим zsh как оболочку по умолчанию
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔁 Меняем оболочку по умолчанию на ZSH..."
    chsh -s $(which zsh)
    echo "✅ Теперь при входе в систему будет запускаться ZSH."
fi

echo "🎉 Всё готово! Перезапустите терминал или выполните:"
echo "   exec zsh"
echo "   kitty"
echo "   p10k configure  # если хотите перенастроить Powerlevel10k"