#!/bin/bash

echo "🚀 Начинаем установку запрошенных приложений на Debian 12..."

# Обновляем систему
sudo apt update && sudo apt upgrade -y

# === 1. authenticator (2FA аутентификатор) ===
# Устанавливаем через flatpak (официальная версия GNOME Authenticator)
if ! command -v flatpak &> /dev/null; then
    echo "📦 Устанавливаем flatpak..."
    sudo apt install -y flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

echo "🔐 Устанавливаем Authenticator..."
flatpak install -y flathub com.github.bilelmoussaoui.Authenticator

# === 2. duf (красивый df — показывает дисковое пространство) ===
echo "📊 Устанавливаем duf..."
sudo apt install -y duf

# === 3. jq (парсер JSON в терминале) ===
echo "🧩 Устанавливаем jq..."
sudo apt install -y jq

# === 4. popsicle (запись образов на флешки) ===
echo "💾 Устанавливаем popsicle..."
sudo apt install -y popsicle popsicle-gtk

# === 5. calamares (инсталлятор Linux — обычно не нужен на установленной системе) ===
echo "🖥️ Устанавливаем calamares (инсталлятор)..."
sudo apt install -y calamares

# === 6. fd (быстрый find) ===
echo "⚡ Устанавливаем fd-find..."
sudo apt install -y fd-find
# Создаём алиас fd → fdfind (в Debian пакет называется fdfind)
echo 'alias fd=fdfind' >> ~/.bashrc
echo 'alias fd=fdfind' >> ~/.zshrc 2>/dev/null

# === 7. koreader (читалка для PDF/ePub на Kindle-подобных устройствах) ===
echo "📚 Устанавливаем koreader через AppImage..."
cd /tmp
wget -O koreader.AppImage https://github.com/koreader/koreader/releases/latest/download/koreader-appimage-x86_64.AppImage
chmod +x koreader.AppImage
sudo mv koreader.AppImage /usr/local/bin/koreader
echo "✅ Koreader установлен. Запуск: koreader"

# === 8. mousai (музыкальный шазам-подобный идентификатор) ===
echo "🎵 Устанавливаем mousai через flatpak..."
flatpak install -y flathub de.sebasjm.Mousai

# === 9. lazyssh (менеджер SSH-подключений в TUI) ===
echo "🔌 Устанавливаем lazyssh через cargo (Rust)..."
if ! command -v cargo &> /dev/null; then
    echo "📦 Устанавливаем Rust (cargo)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi
cargo install lazyssh

# Добавляем в PATH, если ещё не добавлено
if ! grep -q ".cargo/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
fi
if [ -f ~/.zshrc ] && ! grep -q ".cargo/bin" ~/.zshrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
fi

# === 10. linutil (Linux-утилита от LunarVim — красивый TUI-менеджер системных задач) ===
echo "✨ Устанавливаем linutil через cargo..."
cargo install linutil

echo "✅ Все приложения установлены!"

# Перезагружаем оболочку для применения алиасов и PATH
echo "🔄 Применяем изменения в оболочке..."
source ~/.bashrc 2>/dev/null || true

# === Создаём удобные ярлыки (опционально) ===
echo "📌 Создаём .desktop файлы для GUI-приложений..."

# Для Koreader
cat > ~/.local/share/applications/koreader.desktop <<EOF
[Desktop Entry]
Name=KOReader
Comment=E-book reader
Exec=/usr/local/bin/koreader
Icon=org.kde.okular
Terminal=false
Type=Application
Categories=Office;Viewer;
StartupNotify=true
EOF

# Для Authenticator
cat > ~/.local/share/applications/authenticator.desktop <<EOF
[Desktop Entry]
Name=Authenticator
Comment=Two-factor authentication app
Exec=flatpak run com.github.bilelmoussaoui.Authenticator
Icon=com.github.bilelmoussaoui.Authenticator
Terminal=false
Type=Application
Categories=Utility;Security;
StartupNotify=true
EOF

# Для Mousai
cat > ~/.local/share/applications/mousai.desktop <<EOF
[Desktop Entry]
Name=Mousai
Comment=Music recognition app
Exec=flatpak run de.sebasjm.Mousai
Icon=de.sebasjm.Mousai
Terminal=false
Type=Application
Categories=Audio;AudioVideo;
StartupNotify=true
EOF

update-desktop-database ~/.local/share/applications 2>/dev/null

echo "🎉 Готово! Все приложения установлены и доступны."
echo "💡 Запуск:"
echo "   authenticator → flatpak run com.github.bilelmoussaoui.Authenticator"
echo "   duf → duf"
echo "   jq → jq"
echo "   popsicle → popsicle-gtk"
echo "   calamares → calamares"
echo "   fd → fd (алиас на fdfind)"
echo "   koreader → koreader"
echo "   mousai → flatpak run de.sebasjm.Mousai"
echo "   lazyssh → lazyssh"
echo "   linutil → linutil"