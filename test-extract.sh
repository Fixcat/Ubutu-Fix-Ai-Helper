#!/bin/bash

# Тест функции extract_json

# Копируем функцию из fixadm.sh
extract_json() {
    local text="$1"
    
    # Пробуем распарсить весь текст как JSON
    if echo "$text" | jq -e '.type' > /dev/null 2>&1; then
        echo "$text"
        return 0
    fi
    
    # Метод 1: Ищем первый валидный JSON объект построчно
    while IFS= read -r line; do
        if echo "$line" | jq -e '.type' > /dev/null 2>&1; then
            echo "$line"
            return 0
        fi
    done <<< "$text"
    
    # Метод 2: Ищем первый JSON между { и }
    # Используем grep для поиска строк с {"type"
    local json_line=$(echo "$text" | grep -o '{"type"[^}]*}' | head -1)
    if [ -n "$json_line" ] && echo "$json_line" | jq -e '.type' > /dev/null 2>&1; then
        echo "$json_line"
        return 0
    fi
    
    # Метод 3: Простой поиск первого JSON
    # Удаляем все до первой { и берем до первой }
    local json=$(echo "$text" | sed 's/^[^{]*//' | grep -o '{[^}]*}' | head -1)
    if [ -n "$json" ] && echo "$json" | jq -e '.type' > /dev/null 2>&1; then
        echo "$json"
        return 0
    fi
    
    # Не удалось извлечь JSON
    echo "$text"
    return 1
}

# Тестовый текст как от AI
test_text='{"type": "message", "content": "Устанавливаю Marzban в Docker. Пошаговая установка:"}

1. **Клонируем репозиторий Marzban**:
{"type": "command", "command": "git clone https://github.com/Marzban/marzban.git", "explanation": "Клонируем репозиторий Marzban из GitHub"}'

echo "Тестовый текст:"
echo "==============="
echo "$test_text"
echo ""
echo "Результат extract_json:"
echo "======================="
result=$(extract_json "$test_text")
echo "$result"
echo ""
echo "Проверка валидности:"
if echo "$result" | jq -e '.type' > /dev/null 2>&1; then
    echo "✓ JSON валиден"
    echo "Тип: $(echo "$result" | jq -r '.type')"
    echo "Content: $(echo "$result" | jq -r '.content // .command')"
else
    echo "✗ JSON невалиден"
fi
