#!/bin/bash
echo "🔧 Установка базовых инструментов разработчика..."

sudo apt update
sudo apt install -y \
    git curl wget htop neofetch tmux \
    python3-pip nodejs npm build-essential \
    gcc g++ make cmake

# Установка последней версии Node.js через NVM (рекомендуется)
if [ ! -d "$HOME/.nvm" ]; then
    echo "📦 Устанавливаем NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    echo "✅ Node.js LTS установлен через NVM"
fi

# Установка Rust (опционально)
if ! command -v rustc &> /dev/null; then
    echo "📦 Устанавливаем Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo "✅ Dev-инструменты установлены!"