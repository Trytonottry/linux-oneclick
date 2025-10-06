#!/bin/bash

echo "🐳 Устанавливаем Docker и запускаем Arch Linux с pacman..."

# Установка Docker, если не установлен
if ! command -v docker &> /dev/null; then
    echo "📦 Устанавливаем Docker..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    echo "✅ Docker установлен. Перезапустите сессию или выполните:"
    echo "   newgrp docker"
    echo "   ...затем снова запустите этот скрипт."
    exit 0
fi

# Проверяем, есть ли уже контейнер
if [ "$(docker ps -a | grep arch-pacman)" ]; then
    echo "🔄 Запускаем существующий контейнер Arch Linux..."
    docker start -i arch-pacman
else
    echo "📥 Запускаем новый контейнер Arch Linux..."
    docker run -it --name arch-pacman --hostname arch \
        -v "$HOME:/host" \
        -w /root \
        archlinux bash -c "
            echo 'Обновляем систему...';
            pacman -Syu --noconfirm;
            echo '✅ Готово! Вы внутри Arch Linux.';
            echo '💡 Совет: используйте pacman -S пакет';
            echo '📂 Ваш домашний каталог доступен в /host';
            bash
        "
fi

echo "💡 Чтобы снова войти: docker start -i arch-pacman"
echo "🗑️  Чтобы удалить: docker rm arch-pacman"