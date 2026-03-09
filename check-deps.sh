#!/bin/bash

# Скрипт проверки зависимостей для FixAdm

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Проверка зависимостей для FixAdm                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

all_ok=true

# Проверка jq
echo -n "Проверка jq... "
if command -v jq &> /dev/null; then
    version=$(jq --version)
    echo -e "${GREEN}✓ Установлен ($version)${NC}"
else
    echo -e "${RED}✗ Не установлен${NC}"
    echo -e "${YELLOW}  Установите: sudo apt install jq${NC}"
    all_ok=false
fi

# Проверка curl
echo -n "Проверка curl... "
if command -v curl &> /dev/null; then
    version=$(curl --version | head -n1)
    echo -e "${GREEN}✓ Установлен ($version)${NC}"
else
    echo -e "${RED}✗ Не установлен${NC}"
    echo -e "${YELLOW}  Установите: sudo apt install curl${NC}"
    all_ok=false
fi

# Проверка bash версии
echo -n "Проверка bash... "
bash_version=$(bash --version | head -n1)
echo -e "${GREEN}✓ $bash_version${NC}"

echo ""

if [ "$all_ok" = true ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Все зависимости установлены! Можно запускать FixAdm.     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Для установки запустите: sudo ./install.sh"
    echo "Для запуска без установки: ./fixadm.sh"
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Не все зависимости установлены!                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Установите недостающие пакеты:"
    echo "  sudo apt update"
    echo "  sudo apt install -y jq curl"
fi
