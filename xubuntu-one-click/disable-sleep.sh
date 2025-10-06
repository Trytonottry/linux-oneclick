#!/bin/bash
echo "🔌 Отключаем спящий режим в Xubuntu..."

xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/sleep-on-battery -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-battery -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lid-action-on-ac -s 1
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lid-action-on-battery -s 1

echo "✅ Спящий режим отключён навсегда."