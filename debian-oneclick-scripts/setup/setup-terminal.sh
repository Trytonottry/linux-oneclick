#!/bin/bash
# ===================================================================
# Полный one-click скрипт для Debian 12
# Устанавливает zsh, Oh My Zsh, powerlevel10k, Nerd Fonts и утилиты CLI
# ✅ Исправлено: eza теперь устанавливается корректно
# ===================================================================

set -e  # Выход при ошибке

echo "🚀 Запуск полной настройки терминала для Debian 12..."

# -------------------------------
# 1. Обновляем систему
# -------------------------------
sudo apt update && sudo apt upgrade -y

# -------------------------------
# 2. Устанавливаем базовые зависимости
# -------------------------------
sudo apt install -y \
    zsh git curl wget gpg sudo \
    fzf ripgrep \
    tldr \
    nano

# -------------------------------
# 3. Устанавливаем eza (вместо ls)
# -------------------------------
echo "📦 Устанавливаем eza (современная замена ls)..."
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor | sudo tee /usr/share/keyrings/gpg-eza-community.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/gpg-eza-community.gpg] http://deb.giellatekno.com/ eza main" | sudo tee /etc/apt/sources.list.d/giellatekno-eza.list
sudo apt update
sudo apt install -y eza

# -------------------------------
# 4. Устанавливаем bat (вместо cat)
# -------------------------------
echo "📦 Устанавливаем bat (подсветка синтаксиса)..."
sudo apt install -y bat
# Создаём симлинк, если batcat
if command -v batcat >/dev/null 2>&1; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
fi

# -------------------------------
# 5. Устанавливаем fd (вместо find)
# -------------------------------
echo "📦 Устанавливаем fd (быстрый поиск файлов)..."
sudo apt install -y fd-find
# Создаём алиас
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true

# -------------------------------
# 6. Устанавливаем neofetch
# -------------------------------
sudo apt install -y neofetch

# -------------------------------
# 7. Устанавливаем Nerd Fonts (FiraCode)
# -------------------------------
echo "📥 Устанавливаем FiraCode Nerd Font..."
cd /tmp
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip -O FiraCode.zip
sudo mkdir -p /usr/local/share/fonts/FiraCode
sudo unzip -q FiraCode.zip -d /usr/local/share/fonts/FiraCode/
sudo fc-cache -fv
rm -f FiraCode.zip
echo "✅ Шрифт установлен. Выбери 'FiraCode Nerd Font' в настройках терминала."

# -------------------------------
# 8. Устанавливаем Oh My Zsh
# -------------------------------
echo "📦 Устанавливаем Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# -------------------------------
# 9. Устанавливаем powerlevel10k
# -------------------------------
echo "🎨 Устанавливаем powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# -------------------------------
# 10. Устанавливаем плагины
# -------------------------------
echo "🔌 Устанавливаем zsh-autosuggestions и syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# -------------------------------
# 11. Создаём ~/.zshrc
# -------------------------------
echo "📝 Создаём конфиг ~/.zshrc..."
cat > ~/.zshrc << 'EOF'
# ----------------------------------
# Oh My Zsh
# ----------------------------------
export ZSH="$HOME/.oh-my-zsh"

# Тема
ZSH_THEME="powerlevel10k/powerlevel10k"

# Плагины
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  history-substring-search
  docker
  docker-compose
  colored-man-pages
  cp
  sudo
  command-not-found
)

source $ZSH/oh-my-zsh.sh

# Алиасы
alias ll='eza -lbF --color=always --icons=auto'
alias la='eza -laF --color=always --icons=auto'
alias lt='eza --tree -L 2 --color=always --icons=auto'
alias lT='eza --tree --color=always --icons=auto'
alias cat='bat --color=always --style=plain'
alias c='bat --style=numbers,changes,header --color=always'
alias fd='fd'
alias rg='rg'
alias update='sudo apt update && sudo apt upgrade -y'

# Цветной man
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'
export LESS_TERMCAP_ue=$'\e[0m'

# Подсказки
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8a8a8a,italic"

# История
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt inc_append_history

# Комплит
autoload -U compinit && compinit
zstyle ':completion:*' menu select

# Запуск neofetch при старте
neofetch

# Запуск powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

# -------------------------------
# 12. Делаем zsh оболочкой по умолчанию
# -------------------------------
echo "🔁 Делаем zsh оболочкой по умолчанию..."
if ! grep -q "^$(whoami):.*zsh" /etc/passwd; then
    chsh -s /usr/bin/zsh
    echo "✅ zsh установлен как оболочка по умолчанию."
else
    echo "ℹ️ zsh уже установлен как оболочка."
fi

# -------------------------------
# Готово!
# -------------------------------
echo ""
echo "🎉 Готово! Перезапусти терминал или выполни:"
echo ""
echo "    exec zsh"
echo ""
echo "💡 Далее:"
echo "   1. Выбери шрифт 'FiraCode Nerd Font' в настройках терминала"
echo "   2. Пройди мастер настройки powerlevel10k (если откроется)"
echo "   3. Готово — твой терминал стал мощным и красивым!"
echo ""

# Запускаем zsh
exec zsh