#!/bin/bash

ARCH_ROOT="/opt/arch"

echo "🗃️  Устанавливаем Arch Linux в chroot ($ARCH_ROOT)..."

# Установка необходимых пакетов
sudo apt update
sudo apt install -y arch-install-scripts debootstrap

# Создаём директорию
sudo mkdir -p $ARCH_ROOT

# Скачиваем и устанавливаем базовую систему Arch
echo "📥 Скачиваем базовую систему Arch Linux..."
sudo pacstrap -c $ARCH_ROOT base base-devel --ignore linux

# Генерируем fstab (минимальный)
echo "⚙️  Генерируем fstab..."
echo "proc $ARCH_ROOT/proc proc defaults 0 0" | sudo tee -a $ARCH_ROOT/etc/fstab
echo "sysfs $ARCH_ROOT/sys sysfs defaults 0 0" | sudo tee -a $ARCH_ROOT/etc/fstab
echo "tmpfs $ARCH_ROOT/tmp tmpfs defaults 0 0" | sudo tee -a $ARCH_ROOT/etc/fstab

# Монтируем файловые системы
sudo mount -t proc /proc $ARCH_ROOT/proc
sudo mount -t sysfs /sys $ARCH_ROOT/sys
sudo mount -o bind /tmp $ARCH_ROOT/tmp
sudo mount -o bind /dev $ARCH_ROOT/dev
sudo mount -o bind /dev/pts $ARCH_ROOT/dev/pts

# Копируем DNS, чтобы работал интернет
sudo cp /etc/resolv.conf $ARCH_ROOT/etc/

# Входим в chroot
echo "🚪 Входим в Arch Linux chroot. Обновляем систему..."
sudo arch-chroot $ARCH_ROOT /bin/bash -c "
    pacman -Syu --noconfirm;
    echo 'export PS1=\"[ARCH] \w # \"' >> /root/.bashrc;
    echo '✅ Готово! Вы в Arch Linux chroot.';
    echo '💡 Используйте pacman -S пакет';
    echo '🚪 Чтобы выйти — наберите exit';
    bash
"

# После выхода — размонтируем
echo "🧹 Размонтируем файловые системы..."
sudo umount $ARCH_ROOT/{proc,sys,dev/pts,dev,tmp} 2>/dev/null

echo "✅ Вы вышли из chroot."
echo "💡 Чтобы снова войти:"
echo "   sudo arch-chroot $ARCH_ROOT"
echo "🗑️  Чтобы удалить: sudo rm -rf $ARCH_ROOT"