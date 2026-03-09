#!/bin/bash

# Скрипт удаления FixAdm

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           Удаление FixAdm из системы                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Проверка прав root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}⚠️  Для удаления требуются права root${NC}"
    echo -e "${YELLOW}Запустите: sudo ./uninstall.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}Это удалит:${NC}"
echo "  • Исполняемый файл /usr/local/bin/fixadm"
echo "  • Конфигурацию ~/.fixadm-config"
echo "  • Историю команд ~/.fixadm-history"
echo "  • Историю разговоров ~/.fixadm-conversation"
echo ""
echo -e "${RED}Вы уверены? (yes/no):${NC} "
read -r confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Удаление отменено${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}→ Удаление исполняемого файла...${NC}"
if [ -f "/usr/local/bin/fixadm" ]; then
    rm -f /usr/local/bin/fixadm
    echo -e "${GREEN}✓ Удален /usr/local/bin/fixadm${NC}"
else
    echo -e "${YELLOW}⚠ Файл /usr/local/bin/fixadm не найден${NC}"
fi

echo -e "${CYAN}→ Удаление конфигурационных файлов...${NC}"

# Получаем список всех пользователей с домашними директориями
for home_dir in /home/*; do
    if [ -d "$home_dir" ]; then
        username=$(basename "$home_dir")
        
        # Удаляем файлы конфигурации
        if [ -f "$home_dir/.fixadm-config" ]; then
            rm -f "$home_dir/.fixadm-config"
            echo -e "${GREEN}✓ Удален $home_dir/.fixadm-config${NC}"
        fi
        
        if [ -f "$home_dir/.fixadm-history" ]; then
            rm -f "$home_dir/.fixadm-history"
            echo -e "${GREEN}✓ Удален $home_dir/.fixadm-history${NC}"
        fi
        
        if [ -f "$home_dir/.fixadm-conversation" ]; then
            rm -f "$home_dir/.fixadm-conversation"
            echo -e "${GREEN}✓ Удален $home_dir/.fixadm-conversation${NC}"
        fi
    fi
done

# Удаляем файлы root пользователя
if [ -f "/root/.fixadm-config" ]; then
    rm -f /root/.fixadm-config
    echo -e "${GREEN}✓ Удален /root/.fixadm-config${NC}"
fi

if [ -f "/root/.fixadm-history" ]; then
    rm -f /root/.fixadm-history
    echo -e "${GREEN}✓ Удален /root/.fixadm-history${NC}"
fi

if [ -f "/root/.fixadm-conversation" ]; then
    rm -f /root/.fixadm-conversation
    echo -e "${GREEN}✓ Удален /root/.fixadm-conversation${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         FixAdm успешно удален из системы!                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Спасибо за использование FixAdm!${NC}"
echo ""
