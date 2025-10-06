#!/bin/bash

set -e  # Прервать при ошибке

# === Настройки ===
USERNAME="user"          # Замените на желаемое имя пользователя
HOSTNAME="archlinux"     # Имя хоста
TIMEZONE="Europe/Moscow" # Ваш часовой пояс (см. timedatectl list-timezones)
LOCALE="en_US.UTF-8"     # Локаль (можно ru_RU.UTF-8)

echo "🚀 Начинаем пост-установочную настройку Arch Linux..."

# === 1. Настройка времени и локали ===
echo "🕒 Устанавливаем часовой пояс..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "🔤 Настраиваем локаль..."
sed -i "s/#$LOCALE UTF-8/$LOCALE UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# === 2. Настройка hostname ===
echo "$HOSTNAME" > /etc/hostname

# === 3. Обновление зеркал и системы ===
echo "🔄 Обновляем зеркала и систему..."
pacman -Sy --noconfirm pacman-contrib
reflector --country 'Russia' --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
# Если нет России — замените на свою страну или используйте:
# reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

pacman -Syu --noconfirm

# === 4. Установка базовых пакетов ===
echo "📦 Устанавливаем базовые утилиты..."
pacman -S --needed --noconfirm \
    base-devel \
    git \
    openssh \
    tmux \
    neovim \
    sudo \
    htop \
    wget \
    curl \
    rsync \
    bash-completion \
    man-db \
    man-pages

# === 5. Настройка sudo ===
echo "🛡️ Настраиваем sudo для группы wheel..."
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# === 6. Создание обычного пользователя ===
if ! id "$USERNAME" &>/dev/null; then
    echo "👤 Создаём пользователя $USERNAME..."
    useradd -m -G wheel -s /bin/bash "$USERNAME"
    echo "Установите пароль для пользователя $USERNAME:"
    passwd "$USERNAME"
else
    echo "✅ Пользователь $USERNAME уже существует."
fi

# === 7. Настройка и запуск SSH ===
echo "🔌 Включаем и запускаем SSH..."
systemctl enable --now sshd

# === 8. Установка AUR-хелпера (paru) ===
echo "📥 Устанавливаем paru (AUR helper)..."
cd /tmp
sudo -u "$USERNAME" git clone https://aur.archlinux.org/paru.git
cd paru
sudo -u "$USERNAME" makepkg -si --noconfirm
cd ..
rm -rf paru

# === 9. Установка ZeroTier ===
echo "🌐 Устанавливаем ZeroTier через AUR..."
sudo -u "$USERNAME" paru -S --noconfirm zerotier-one

# Включаем ZeroTier
systemctl enable --now zerotier-one

# === 10. Базовая настройка tmux и nvim для пользователя ===
echo "📝 Настраиваем tmux и nvim для $USERNAME..."

# .tmux.conf
sudo -u "$USERNAME" mkdir -p "/home/$USERNAME/.config"
cat > "/home/$USERNAME/.tmux.conf" <<EOF
set -g mouse on
set -g default-terminal "screen-256color"
set -g status-bg colour234
set -g status-fg white
EOF
chown "$USERNAME":"$USERNAME" "/home/$USERNAME/.tmux.conf"

# init.lua для Neovim
NVIM_DIR="/home/$USERNAME/.config/nvim"
mkdir -p "$NVIM_DIR"
cat > "$NVIM_DIR/init.lua" <<EOF
-- Базовая конфигурация Neovim
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.mouse = 'a'
vim.opt.termguicolors = true
EOF
chown -R "$USERNAME":"$USERNAME" "$NVIM_DIR"

# === 11. Очистка ===
echo "🧹 Очищаем кэш пакетов..."
pacman -Sc --noconfirm

# === Готово! ===
echo "✅ Настройка завершена!"
echo "💡 Дальнейшие шаги:"
echo " - Перезагрузитесь: systemctl reboot"
echo " - Войдите как $USERNAME"
echo " - Присоединяйтесь к ZeroTier: sudo zerotier-cli join <NETWORK_ID>"
echo " - Используйте: tmux, nvim, ssh"
