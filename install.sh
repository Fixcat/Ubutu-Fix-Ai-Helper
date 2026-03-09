#!/bin/bash

# Скрипт установки FixAdm

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          Установка FixAdm для Ubuntu Linux                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  Для установки требуются права root"
    echo "Запустите: sudo ./install.sh"
    exit 1
fi

# Проверка зависимостей
echo "→ Проверка зависимостей..."
missing_deps=false

if ! command -v jq &> /dev/null; then
    echo "  ✗ jq не установлен"
    missing_deps=true
else
    echo "  ✓ jq установлен"
fi

if ! command -v curl &> /dev/null; then
    echo "  ✗ curl не установлен"
    missing_deps=true
else
    echo "  ✓ curl установлен"
fi

if [ "$missing_deps" = true ]; then
    echo ""
    echo "⚠️  Не все зависимости установлены!"
    echo "Установите их вручную:"
    echo "  sudo apt install -y jq curl"
    echo ""
    read -p "Попробовать установить автоматически? (y/n): " install_deps
    
    if [[ $install_deps =~ ^[Yy]$ ]]; then
        echo "→ Установка зависимостей..."
        apt install -y jq curl 2>&1 | grep -v "^W:" | grep -v "^E:" || true
    else
        echo "Установка отменена. Установите зависимости и попробуйте снова."
        exit 1
    fi
fi

echo "→ Копирование скрипта..."
cp fixadm.sh /usr/local/bin/fixadm
chmod +x /usr/local/bin/fixadm

echo ""
echo "✓ Установка завершена успешно!"
echo ""
echo "Для запуска введите: fixadm"
echo ""
