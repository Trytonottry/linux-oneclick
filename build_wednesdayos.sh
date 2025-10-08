#!/bin/bash

# Проверка прав суперпользователя
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт требует прав root. Запустите его с sudo."
   exit 1
fi

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Начинаю выполнение скрипта...${NC}"

# Клонирование репозитория
echo -e "${GREEN}Клонирование репозитория...${NC}"
if ! git clone https://github.com/WednesdayOS/base; then
    echo -e "${RED}Ошибка при клонировании репозитория.${NC}"
    exit 1
fi

# Установка archiso через pacman
echo -e "${GREEN}Установка archiso...${NC}"
if ! pacman -S --noconfirm archiso; then
    echo -e "${RED}Ошибка при установке archiso.${NC}"
    exit 1
fi

# Переход в директорию и сборка образа
cd base || { echo -e "${RED}Не удалось перейти в папку 'base'.${NC}"; exit 1; }

echo -e "${GREEN}Запуск mkarchiso...${NC}"
if ! mkarchiso -v; then
    echo -e "${RED}Ошибка при выполнении mkarchiso.${NC}"
    exit 1
fi

echo -e "${GREEN}Сборка завершена успешно!${NC}"
