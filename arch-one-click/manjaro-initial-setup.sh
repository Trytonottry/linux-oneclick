#!/bin/bash

set -e  # Прервать выполнение при ошибке

echo "🚀 Начинаем первоначальную настройку Manjaro..."

# Обновление системы
echo "🔄 Обновляем систему..."
sudo pacman -Syu --noconfirm

# Установка базовых утилит
echo "📦 Устанавливаем базовые пакеты: ssh, tmux, neovim..."
sudo pacman -S --needed --noconfirm openssh tmux neovim git base-devel

# Настройка SSH (включение и запуск службы)
echo "🔧 Настраиваем и запускаем SSH..."
sudo systemctl enable --now sshd

# Установка AUR-хелпера paru (если не установлен)
if ! command -v paru &> /dev/null; then
    echo "📥 Устанавливаем AUR-хелпер paru..."
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/paru
else
    echo "✅ paru уже установлен."
fi

# Установка Hyperland через AUR
echo "🖥️ Устанавливаем Hyperland..."
paru -S --needed --noconfirm hyperland

# Установка ZeroTier
echo "🌐 Устанавливаем ZeroTier..."
paru -S --needed --noconfirm zerotier-one

# Запуск и включение ZeroTier
echo "🔌 Запускаем и включаем ZeroTier..."
sudo systemctl enable --now zerotier-one

# Опционально: создать базовый конфиг .tmux.conf
if [ ! -f ~/.tmux.conf ]; then
    echo "📝 Создаём базовый .tmux.conf..."
    cat > ~/.tmux.conf <<EOF
set -g mouse on
set -g default-terminal "screen-256color"
set -g status-bg black
set -g status-fg white
EOF
fi

# Опционально: базовый конфиг Neovim (если нет ~/.config/nvim)
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
    echo "📝 Создаём базовую структуру Neovim..."
    mkdir -p "$NVIM_CONFIG_DIR"
    cat > "$NVIM_CONFIG_DIR/init.lua" <<EOF
-- Базовый init.lua для Neovim
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.mouse = 'a'
EOF
fi

echo "✅ Настройка завершена!"
echo "💡 Советы:"
echo " - Перезагрузитесь, чтобы использовать сессию Hyperland (выберите 'Hyprland' в меню входа)."
echo " - Присоединяйтесь к сети ZeroTier: sudo zerotier-cli join <NETWORK_ID>"
echo " - Запускайте tmux: tmux"
echo " - Редактируйте файлы в nvim: nvim <файл>"
