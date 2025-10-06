#!/bin/bash

# ───────────────────────────────────────────────
# 🐧 Полная настройка Linux терминала (Debian)
# fish + starship + picom + vim + themes + fonts
# Автор: moriarty
# Запуск: sudo bash setup-terminal.sh
# ───────────────────────────────────────────────

set -euo pipefail
echo "🚀 Запуск полной настройки терминала..."

# Проверка на Debian/Ubuntu
if ! grep -q "debian\|ubuntu" /etc/os-release; then
    echo "❗ Этот скрипт предназначен для Debian/Ubuntu"
    exit 1
fi

# Проверка sudo
if [ "$EUID" -ne 0 ]; then
    echo "❗ Запускай через sudo"
    exit 1
fi

# Имя текущего пользователя
USERNAME=$(logname 2>/dev/null || echo $SUDO_USER)
USERHOME=$(getent passwd "$USERNAME" | cut -d: -f6)

echo "🔧 Пользователь: $USERNAME"
echo "🏠 Домашняя папка: $USERHOME"

# ───────────────────────────────────────────────
# 1. Обновление системы
# ───────────────────────────────────────────────
echo "📦 Обновление системы..."
apt update && apt upgrade -y

# ───────────────────────────────────────────────
# 2. Установка пакетов
# ───────────────────────────────────────────────
echo "📦 Установка необходимых пакетов..."
apt install -y \
    fish curl wget unzip git \
    fzf ripgrep fd-find \
    bat tree httpie jq \
    lxappearance \
    ca-certificates fonts-liberation

# Создаём алиас для bat
ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true

# ───────────────────────────────────────────────
# 3. Установка exa
# ───────────────────────────────────────────────
echo "📦 Установка exa..."
EXA_URL="https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip"
cd /tmp || exit
curl -LO "$EXA_URL"
unzip -o exa-linux-x86_64-v0.10.1.zip
mv exa-linux-x86_64 /usr/local/bin/exa
rm exa-linux-x86_64-v0.10.1.zip

# ───────────────────────────────────────────────
# 4. Установка starship
# ───────────────────────────────────────────────
echo "📦 Установка starship..."
curl -fsSL https://starship.rs/install.sh | sh

# ───────────────────────────────────────────────
# 5. Установка picom
# ───────────────────────────────────────────────
echo "📦 Установка picom..."
apt install -y picom

# Конфиг picom
PICOM_DIR="$USERHOME/.config/picom"
mkdir -p "$PICOM_DIR"
cat > "$PICOM_DIR/picom.conf" << 'EOF'
# picom.conf — минимальный и валидный
backend = "glx";
vsync = true;
use-damage = true;
paint-on-overlay = true;

shadow = true;
shadow-radius = 15;
shadow-offset-x = -5;
shadow-offset-y = -5;
shadow-opacity = 0.7;
no-dnd-shadow = true;
no-dock-shadow = true;
shadow-exclude = [
  "window_type = 'notification'",
  "window_type = 'tooltip'"
];

fading = true;
fade-delta = 10;
fade-in-step = 0.03;
fade-out-step = 0.03;

wintypes = {
  tooltip = { shadow = false; };
  popup_menu = { shadow = false; };
  dropdown_menu = { shadow = false; };
};

mark-wmwin-focused = true;
detect-transient = true;
unredir-if-possible = true;
EOF

# ───────────────────────────────────────────────
# 6. Установка fisher + tide
# ───────────────────────────────────────────────
echo "🐚 Установка fish, fisher, tide..."
su - "$USERNAME" -c "
    curl -sL https://git.io/fisher | source
    mkdir -p ~/.config/fish
    echo 'set -U fish_greeting' >> ~/.config/fish/config.fish
    fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
    fish -c 'fisher install IlanCosman/tide@v5'
"

# ───────────────────────────────────────────────
# 7. Конфиг fish + starship
# ───────────────────────────────────────────────
FISH_CONFIG="$USERHOME/.config/fish/config.fish"
cat > "$FISH_CONFIG" << 'EOF'
# ───────────────────────────────────────
# 🐟 Fish + Starship + Алиасы
# ───────────────────────────────────────

set -U fish_greeting
set -U fish_autosuggestion_enabled yes
set -U fish_history_ignore_dups yes

# PATH
set -Ua fish_user_paths ~/.local/bin /usr/local/bin

# Алиасы
abbr ll 'ls -lh'
abbr la 'ls -lha'
abbr gs 'git status'
abbr gd 'git diff'
abbr dps 'docker ps'
abbr venv 'python -m venv .venv && source .venv/bin/activate'

# exa
alias ls='exa'
alias l='exa'
alias ll='exa -lbgh'
alias tree='exa --tree --level=3'

# bat
alias cat='bat'

# zoxide
zoxide init fish | source

# starship
starship init fish | source
EOF

# ───────────────────────────────────────────────
# 8. Установка vim + .vimrc
# ───────────────────────────────────────────────
su - "$USERNAME" -c "
    apt install -y vim
    mkdir -p ~/.vim/autoload
    curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"

VIMRC="$USERHOME/.vimrc"
cat > "$VIMRC" << 'EOF'
syntax on
set number relativenumber
set tabstop=4 shiftwidth=4 expandtab
set autoindent smartindent
set hlsearch incsearch
set clipboard=unnamed,unnamedplus
set mouse=a
set colorcolumn=80
highlight ColorColumn ctermbg=darkgray

call plug#begin('~/.vim/plugged')
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'vim-airline/vim-airline'
Plug 'preservim/nerdtree'
Plug 'luochen1990/rainbow'
call plug#end()

colorscheme dracula
set background=dark

nnoremap <leader>f :NERDTreeToggle<CR>
let mapleader = ","

autocmd BufWritePre * :%s/\s\+$//e
EOF

# ───────────────────────────────────────────────
# 9. Установка тем и иконок
# ───────────────────────────────────────────────
echo "🎨 Установка тем и иконок..."
apt install -y arc-theme
su - "$USERNAME" -c "curl -Lo /tmp/papirus.tar.xz https://git.io/papirus-icon-theme-latest"
su - "$USERNAME" -c "mkdir -p ~/.icons && tar -xf /tmp/papirus.tar.xz -C ~/.icons"

# ───────────────────────────────────────────────
# 10. Установка Nerd Font
# ───────────────────────────────────────────────
echo "🔤 Установка JetBrainsMono Nerd Font..."
su - "$USERNAME" -c "
    mkdir -p ~/.fonts
    cd ~/.fonts
    curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip
    fc-cache -fv
"

# ───────────────────────────────────────────────
# 11. Автозагрузка picom
# ───────────────────────────────────────────────
AUTOSTART="$USERHOME/.xprofile"
cat > "$AUTOSTART" << 'EOF'
#!/bin/sh
if ! pgrep -x picom > /dev/null; then
    picom --config ~/.config/picom/picom.conf --experimental-backends --daemon
fi
EOF
chmod +x "$AUTOSTART"

# ───────────────────────────────────────────────
# 12. Сделать fish оболочкой по умолчанию
# ───────────────────────────────────────────────
echo "🐚 Делаем fish основной оболочкой..."
chsh -s /usr/bin/fish "$USERNAME"

# ───────────────────────────────────────────────
# 🎉 Готово!
# ───────────────────────────────────────────────
echo "✅ Настройка завершена!"
echo "📌 Перезагрузи систему или войди заново."
echo "🔥 Ты теперь — terminal god."
exit 0