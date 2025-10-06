#!/bin/bash

# Установка и настройка виртуального окружения Python на Debian

set -e  # Прерывать выполнение при ошибке

echo "🔄 Обновление системы..."
sudo apt update && sudo apt upgrade -y

echo "📦 Установка Python и необходимых пакетов..."
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Проверка наличия python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Ошибка: Python3 не установлен."
    exit 1
fi

# Проверка pip
if ! command -v pip3 &> /dev/null; then
    echo "⚠️ pip3 не найден, устанавливаем..."
    sudo apt install -y python3-pip
fi

# Создание виртуального окружения
VENV_DIR="venv"
if [ -d "$VENV_DIR" ]; then
    echo "🗑️ Удаляем старое виртуальное окружение..."
    rm -rf "$VENV_DIR"
fi

echo "🔧 Создаём виртуальное окружение в папке '$VENV_DIR'..."
python3 -m venv "$VENV_DIR"

# Активация и настройка
echo "⚡ Активируем виртуальное окружение и обновляем pip..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo "✅ Виртуальное окружение готово!"
echo ""
echo "📌 Как использовать:"
echo "   source $VENV_DIR/bin/activate     # Активировать"
echo "   deactivate                        # Деактивировать"
echo ""
echo "💡 Текущий Python: $(which python)"
echo "💡 Текущий pip: $(which pip)"
echo "💡 Версия Python: $(python --version)"

# Предложение добавить деактивацию
echo ""
echo "🚀 Вы уже в виртуальном окружении. Чтобы выйти — выполните: deactivate"