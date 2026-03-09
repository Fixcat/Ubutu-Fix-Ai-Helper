#!/bin/bash

# Скрипт для диагностики проблем с FixAdm

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          Диагностика FixAdm                                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Проверка версии
echo "→ Проверка версии..."
if [ -f "fixadm.sh" ]; then
    version=$(grep 'CURRENT_VERSION=' fixadm.sh | head -1 | cut -d'"' -f2)
    echo "✓ Версия: $version"
else
    echo "✗ Файл fixadm.sh не найден"
    exit 1
fi
echo ""

# Проверка зависимостей
echo "→ Проверка зависимостей..."
if command -v jq &> /dev/null; then
    echo "✓ jq установлен: $(jq --version)"
else
    echo "✗ jq не установлен"
    echo "  Установите: sudo apt install -y jq"
fi

if command -v curl &> /dev/null; then
    echo "✓ curl установлен: $(curl --version | head -1)"
else
    echo "✗ curl не установлен"
    echo "  Установите: sudo apt install -y curl"
fi
echo ""

# Проверка конфигурации
echo "→ Проверка конфигурации..."
CONFIG_FILE="$HOME/.fixadm-config"
if [ -f "$CONFIG_FILE" ]; then
    echo "✓ Конфигурация найдена: $CONFIG_FILE"
    source "$CONFIG_FILE"
    echo "  Провайдер: $PROVIDER"
    echo "  Модель: $MODEL_ID"
    echo "  API ключ: ${API_KEY:0:10}...${API_KEY: -4}"
    
    # Проверка API ключа
    if [ -z "$API_KEY" ]; then
        echo "✗ API ключ не установлен"
    else
        echo "✓ API ключ установлен"
    fi
else
    echo "✗ Конфигурация не найдена"
    echo "  Запустите fixadm для первоначальной настройки"
fi
echo ""

# Проверка файлов истории
echo "→ Проверка файлов истории..."
CONVERSATION_FILE="$HOME/.fixadm-conversation"
if [ -f "$CONVERSATION_FILE" ]; then
    msg_count=$(cat "$CONVERSATION_FILE" | jq 'length' 2>/dev/null || echo "0")
    echo "✓ История разговора: $msg_count сообщений"
else
    echo "○ История разговора пуста (это нормально для первого запуска)"
fi
echo ""

# Тест API (если конфигурация есть)
if [ -f "$CONFIG_FILE" ] && [ -n "$API_KEY" ]; then
    echo "→ Тест API соединения..."
    echo "  Провайдер: $PROVIDER"
    
    case $PROVIDER in
        openai)
            echo "  Тестирую OpenAI API..."
            response=$(curl -s -w "\n%{http_code}" https://api.openai.com/v1/chat/completions \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $API_KEY" \
                -d '{
                    "model": "'"$MODEL_ID"'",
                    "messages": [{"role": "user", "content": "test"}],
                    "max_tokens": 5
                }')
            
            http_code=$(echo "$response" | tail -1)
            body=$(echo "$response" | head -n -1)
            
            if [ "$http_code" = "200" ]; then
                echo "✓ API работает (HTTP $http_code)"
            else
                echo "✗ Ошибка API (HTTP $http_code)"
                echo "$body" | jq '.' 2>/dev/null || echo "$body"
            fi
            ;;
            
        claude)
            echo "  Тестирую Claude API..."
            response=$(curl -s -w "\n%{http_code}" https://api.anthropic.com/v1/messages \
                -H "Content-Type: application/json" \
                -H "x-api-key: $API_KEY" \
                -H "anthropic-version: 2023-06-01" \
                -d '{
                    "model": "'"$MODEL_ID"'",
                    "max_tokens": 5,
                    "messages": [{"role": "user", "content": "test"}]
                }')
            
            http_code=$(echo "$response" | tail -1)
            body=$(echo "$response" | head -n -1)
            
            if [ "$http_code" = "200" ]; then
                echo "✓ API работает (HTTP $http_code)"
            else
                echo "✗ Ошибка API (HTTP $http_code)"
                echo "$body" | jq '.' 2>/dev/null || echo "$body"
            fi
            ;;
            
        github)
            echo "  Тестирую GitHub Models API..."
            response=$(curl -s -w "\n%{http_code}" https://models.inference.ai.azure.com/chat/completions \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $API_KEY" \
                -d '{
                    "model": "'"$MODEL_ID"'",
                    "messages": [{"role": "user", "content": "test"}],
                    "max_tokens": 5
                }')
            
            http_code=$(echo "$response" | tail -1)
            body=$(echo "$response" | head -n -1)
            
            if [ "$http_code" = "200" ]; then
                echo "✓ API работает (HTTP $http_code)"
            else
                echo "✗ Ошибка API (HTTP $http_code)"
                echo "$body" | jq '.' 2>/dev/null || echo "$body"
            fi
            ;;
    esac
else
    echo "○ Пропуск теста API (нет конфигурации)"
fi
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║          Диагностика завершена                             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Если обнаружены проблемы:"
echo "  1. Проверьте API ключ и модель"
echo "  2. Запустите с отладкой: DEBUG=1 fixadm"
echo "  3. Проверьте баланс аккаунта у провайдера"
echo "  4. Создайте issue: https://github.com/Fixcat/Ubutu-Fix-Ai-Helper/issues"
echo ""
