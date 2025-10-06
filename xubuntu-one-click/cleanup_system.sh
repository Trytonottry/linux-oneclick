#!/bin/bash
echo "🧹 Запуск глубокой очистки системы..."

sudo apt autoremove -y
sudo apt autoclean -y
sudo journalctl --vacuum-time=7d
sudo rm -rf /tmp/*
[ -d "$HOME/.cache" ] && rm -rf $HOME/.cache/*
sudo flatpak uninstall --unused -y 2>/dev/null
yes | sudo snap remove --purge $(snap list --all | grep disabled | awk '{print $1}') 2>/dev/null

echo "✅ Система очищена!"