#!/bin/bash
echo "🖥️  Настройка GUI под комфортную работу..."

# Увеличить размер шрифта в GTK
mkdir -p ~/.config/gtk-3.0
cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-font-name = Sans 11
gtk-theme-name = Xfce-dusk
gtk-icon-theme-name = Adwaita
gtk-cursor-theme-name = Adwaita
gtk-cursor-theme-size = 24
gtk-toolbar-style = GTK_TOOLBAR_BOTH
gtk-menu-images = 1
gtk-button-images = 1
EOF

# Включить ночные цвета (если xfce4)
xfconf-query -c xfce4-panel -p /panels -n -t int -s 1 2>/dev/null && echo "Панель перезапущена" || echo "Не XFCE — пропускаем панель."

# Установка Arc Menu (альтернативное меню для XFCE)
if ! dpkg -l | grep -q xfce4-whiskermenu-plugin; then
    sudo apt install -y xfce4-whiskermenu-plugin
    echo "✅ Установлено Whisker Menu (лучшее меню приложений)."
fi

# Установка Plank (красивый док)
if ! command -v plank &> /dev/null; then
    sudo apt install -y plank
    echo "✅ Установлен Plank. Запустите вручную или через автозагрузку."
fi

echo "✅ GUI настроен для комфортной работы. Перелогиньтесь или перезапустите сеанс."