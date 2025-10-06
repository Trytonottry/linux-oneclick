#!/bin/bash

echo "🔑 Настройка SSH-ключей для всех серверов..."

# --- 1. Создаём SSH-ключ (без пароля) ---
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo "Генерируем SSH-ключ..."
    ssh-keygen -t ed25519 -C "auto-setup" -N "" -f "$HOME/.ssh/id_ed25519"
else
    echo "SSH-ключ уже существует."
fi

# --- 2. Функция для копирования ключа и проверки ---
setup_server() {
    local user="$1"
    local host="$2"
    echo "📡 Настройка $user@$host..."
    
    # Копируем ключ
    ssh-copy-id -o StrictHostKeyChecking=no "$user@$host"
    
    # Проверяем подключение
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$user@$host" "echo OK" 2>/dev/null; then
        echo "✅ $user@$host — готов!"
    else
        echo "❌ $user@$host — ошибка подключения!"
    fi
    echo ""
}

# --- 3. Настраиваем все серверы ---
setup_server "host1" "10.147.19.25"
setup_server "kali" "10.147.19.210"
setup_server "root" "10.147.19.180"

echo "🎉 Все серверы настроены!"