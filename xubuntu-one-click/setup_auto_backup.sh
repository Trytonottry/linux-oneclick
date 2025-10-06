#!/bin/bash
BACKUP_DIR="$HOME/backups"
mkdir -p "$BACKUP_DIR"

CRON_CMD="0 2 * * * tar -czf $BACKUP_DIR/home-\$(date +\%Y\%m\%d).tar.gz -C $HOME . --exclude='*/backups' --exclude='*/.cache' --exclude='*/Downloads'"

# Добавляем в cron, если ещё не добавлено
(crontab -l 2>/dev/null | grep -q "home-backup") || {
    (crontab -l 2>/dev/null; echo "$CRON_CMD # home-backup") | crontab -
    echo "✅ Ежедневное резервное копирование в $BACKUP_DIR настроено (в 2:00 ночи)."
}

echo "📦 Пример ручного запуска:"
echo "tar -czf $BACKUP_DIR/home-\$(date +\%Y\%m\%d).tar.gz -C $HOME . --exclude='*/backups' --exclude='*/.cache' --exclude='*/Downloads'"