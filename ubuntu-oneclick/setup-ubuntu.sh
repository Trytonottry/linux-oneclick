#!/bin/bash
set -e

echo "🔄 Обновление системы..."
sudo apt update && sudo apt upgrade -y

echo "🧰 Установка базовых утилит..."
sudo apt install -y curl wget git software-properties-common apt-transport-https ca-certificates gpg

echo "📦 Установка snapd и flatpak..."
sudo apt install -y snapd flatpak gnome-software-plugin-flatpak
sudo systemctl enable --now snapd.socket

echo "🌐 Добавление Flathub..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "💻 Установка приложений через APT..."
sudo apt install -y tmux krusader kitty filezilla gedit neofetch htop nvim

echo "🧩 Установка Visual Studio Code..."
if ! command -v code &> /dev/null; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/ms_vscode.gpg >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ms_vscode.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt update && sudo apt install -y code
fi

echo "💬 Установка Telegram Desktop..."
sudo apt install -y telegram-desktop

echo "⚙️ Установка ZeroTier..."
curl -s https://install.zerotier.com | sudo bash

echo "🧱 Установка Obsidian (через Flatpak)..."
flatpak install -y flathub md.obsidian.Obsidian

echo "💡 Установка Oh-My-Bash..."
if [ ! -d "$HOME/.oh-my-bash" ]; then
    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git ~/.oh-my-bash
    cp ~/.oh-my-bash/templates/bashrc.osh-template ~/.bashrc
    echo "✅ Oh-My-Bash установлен. Перезапусти терминал для применения."
else
    echo "⚙️ Oh-My-Bash уже установлен."
fi 

echo "✅ Все программы установлены!"
echo "---------------------------------------------------"
echo "📦 Установлено:"
echo "tmux, VS Code, Krusader, Kitty, Obsidian, FileZilla,"
echo "Telegram Desktop, ZeroTier, Gedit"
echo "---------------------------------------------------"
echo "💡 Совет: перезагрузи систему, чтобы Snap/Flatpak"
echo "службы корректно подхватились."

