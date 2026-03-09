#!/bin/bash

# FixAdm - AI-powered консольный администратор для Ubuntu
# Поддержка: OpenAI, Claude (Anthropic), GitHub Models

set -e

# Цвета для оформления
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Файлы конфигурации
CONFIG_FILE="$HOME/.fixadm-config"
HISTORY_FILE="$HOME/.fixadm-history"
CONVERSATION_FILE="$HOME/.fixadm-conversation"

# Глобальные переменные
PROVIDER=""
API_KEY=""
MODEL_ID=""
MAX_MESSAGES=50

# Системный промпт для AI (используется всеми провайдерами)
SYSTEM_PROMPT="Ты - FixAdm, AI администратор Linux систем. Ты помогаешь пользователю администрировать Ubuntu сервер. 

КРИТИЧЕСКИ ВАЖНЫЕ ПРАВИЛА:

1. НИКОГДА не используй 'sudo apt update' или 'apt update' - на этой системе проблемы с репозиториями. Сразу устанавливай: sudo apt install -y <пакет>

2. НИКОГДА не используй интерактивные редакторы (nano, vim, vi, emacs) - они зависают в этой среде!

3. ДЛЯ РЕДАКТИРОВАНИЯ ФАЙЛОВ используй ТОЛЬКО эти методы:
   - Создание файла: cat << 'EOF' | sudo tee /path/to/file
   - Добавление: echo 'строка' | sudo tee -a /path/to/file
   - Замена: sudo sed -i 's/старый/новый/g' /path/to/file

4. ОБРАБОТКА ОШИБОК - У ТЕБЯ 5 ПОПЫТОК:
   - После каждой команды ты получишь результат
   - При ошибке АНАЛИЗИРУЙ текст ошибки
   - КАЖДАЯ попытка = ДРУГОЙ подход (не повторяй команду!)
   - У тебя максимум 5 попыток на задачу
   
   ТИПЫ ОШИБОК И РЕШЕНИЯ:
   \"permission denied\" → добавь sudo или usermod -aG
   \"not found\" / \"no such file\" → пакет не существует, используй Docker/snap/исходники
   \"port already in use\" → измени порт или останови конфликтующий процесс
   \"connection refused\" → запусти сервис (systemctl start)
   
   ПРИМЕР РАЗНЫХ ПОДХОДОВ:
   Попытка 1: docker run ... → ОШИБКА: permission denied
   Попытка 2: sudo docker run ... → добавляем sudo
   Попытка 3: sudo usermod -aG docker \$USER && newgrp docker && docker run ...

5. ФОРМАТ ОТВЕТА - СТРОГО JSON, БЕЗ ЛИШНЕГО ТЕКСТА:
   
   КРИТИЧЕСКИ ВАЖНО: Отвечай ТОЛЬКО ОДНИМ JSON объектом за раз!
   
   Для команды:
   {\\\"type\\\": \\\"command\\\", \\\"command\\\": \\\"команда\\\", \\\"explanation\\\": \\\"что делаем\\\"}
   
   Для сообщения:
   {\\\"type\\\": \\\"message\\\", \\\"content\\\": \\\"текст\\\"}
   
   ЗАПРЕЩЕНО:
   ❌ Несколько JSON в одном ответе
   ❌ Текст до или после JSON
   ❌ Markdown форматирование (тройные кавычки, жирный текст)
   ❌ Нумерованные списки с JSON
   ❌ Объяснения вне JSON
   
   ПРАВИЛЬНО:
   ✓ {\\\"type\\\": \\\"command\\\", \\\"command\\\": \\\"git clone ...\\\", \\\"explanation\\\": \\\"Клонируем репозиторий\\\"}
   
   НЕПРАВИЛЬНО:
   ✗ Сначала клонируем: {\\\"type\\\": \\\"command\\\"...}
   ✗ {\\\"type\\\": \\\"message\\\"...} затем {\\\"type\\\": \\\"command\\\"...}
   ✗ 1. Команда: {\\\"type\\\": \\\"command\\\"...}
   
   После выполнения команды ты получишь результат и АВТОМАТИЧЕСКИ продолжишь.
   Не нужно отправлять все команды сразу - отправляй по одной!

6. После ПОЛНОЙ установки сервиса дай инструкцию:
   {\\\"type\\\": \\\"message\\\", \\\"content\\\": \\\"Установка завершена!\\\\n\\\\nДоступ: http://IP:8000\\\\nЛогин: admin\\\\nПароль: admin\\\\n\\\\nКоманды:\\\\n- Статус: docker ps\\\\n- Логи: docker logs marzban\\\"}"

# Информация о репозитории
REPO_URL="https://github.com/Fixcat/Ubutu-Fix-Ai-Helper"
REPO_RAW_URL="https://raw.githubusercontent.com/Fixcat/Ubutu-Fix-Ai-Helper/main"
CURRENT_VERSION="1.1.2"
UPDATE_CHECK_FILE="$HOME/.fixadm-last-update-check"

# Функция для проверки обновлений
check_for_updates() {
    # Проверяем не чаще раза в день
    if [ -f "$UPDATE_CHECK_FILE" ]; then
        local last_check=$(cat "$UPDATE_CHECK_FILE")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_check))
        
        # Если прошло меньше 24 часов (86400 секунд), пропускаем проверку
        if [ $time_diff -lt 86400 ]; then
            return
        fi
    fi
    
    echo -e "${CYAN}→ Проверка обновлений...${NC}"
    
    # Получаем версию с GitHub
    local remote_version=$(curl -s "$REPO_RAW_URL/VERSION" | grep -oP 'FixAdm v\K[0-9.]+' | head -1)
    
    if [ -z "$remote_version" ]; then
        # Не удалось получить версию, пропускаем
        return
    fi
    
    # Сохраняем время последней проверки
    date +%s > "$UPDATE_CHECK_FILE"
    
    # Сравниваем версии
    if [ "$remote_version" != "$CURRENT_VERSION" ]; then
        echo ""
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║${WHITE}${BOLD}           Доступна новая версия FixAdm!                ${NC}${YELLOW}║${NC}"
        echo -e "${YELLOW}╠════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC} Текущая версия: ${RED}$CURRENT_VERSION${NC}"
        echo -e "${YELLOW}║${NC} Новая версия:    ${GREEN}$remote_version${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}Хотите обновить сейчас? (y/n):${NC} "
        read -r update_choice
        
        if [[ $update_choice =~ ^[Yy]$ ]]; then
            update_fixadm
        else
            echo -e "${YELLOW}Вы можете обновить позже командой: fixadm --update${NC}"
            echo ""
        fi
    else
        echo -e "${GREEN}✓ У вас установлена последняя версия${NC}"
    fi
}

# Функция для обновления FixAdm
update_fixadm() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Обновление FixAdm                             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Создаем временную директорию
    local temp_dir=$(mktemp -d)
    
    echo -e "${CYAN}→ Скачивание обновления...${NC}"
    
    # Клонируем репозиторий
    if git clone --depth 1 "$REPO_URL.git" "$temp_dir" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Обновление скачано${NC}"
        
        # Создаем бэкап текущей версии
        if [ -f "/usr/local/bin/fixadm" ]; then
            echo -e "${CYAN}→ Создание резервной копии...${NC}"
            sudo cp /usr/local/bin/fixadm /usr/local/bin/fixadm.backup
            echo -e "${GREEN}✓ Резервная копия создана: /usr/local/bin/fixadm.backup${NC}"
        fi
        
        # Устанавливаем новую версию
        echo -e "${CYAN}→ Установка обновления...${NC}"
        cd "$temp_dir"
        chmod +x install.sh
        
        if sudo ./install.sh > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Обновление установлено успешно!${NC}"
            echo ""
            echo -e "${YELLOW}Изменения вступят в силу при следующем запуске.${NC}"
            echo -e "${CYAN}Перезапустите FixAdm командой: fixadm${NC}"
            echo ""
            
            # Показываем changelog
            if [ -f "$temp_dir/CHANGELOG.md" ]; then
                echo -e "${CYAN}Что нового:${NC}"
                head -20 "$temp_dir/CHANGELOG.md"
                echo ""
            fi
            
            # Удаляем временную директорию
            rm -rf "$temp_dir"
            
            exit 0
        else
            echo -e "${RED}✗ Ошибка при установке обновления${NC}"
            
            # Восстанавливаем из бэкапа
            if [ -f "/usr/local/bin/fixadm.backup" ]; then
                echo -e "${CYAN}→ Восстановление из резервной копии...${NC}"
                sudo mv /usr/local/bin/fixadm.backup /usr/local/bin/fixadm
                echo -e "${GREEN}✓ Восстановлено${NC}"
            fi
            
            rm -rf "$temp_dir"
        fi
    else
        echo -e "${RED}✗ Не удалось скачать обновление${NC}"
        echo -e "${YELLOW}Проверьте подключение к интернету${NC}"
        rm -rf "$temp_dir"
    fi
    
    echo ""
    echo -e "${CYAN}Нажмите Enter для продолжения...${NC}"
    read
}

# Функция для красивого вывода заголовка
print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                        FixAdm v1.1.2                   ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}      AI-powered администратор для Ubuntu Linux         ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Функция для вывода меню
print_menu() {
    echo -e "${YELLOW}Выберите AI провайдера:${NC}"
    echo -e "${GREEN}1)${NC} OpenAI (GPT-4, GPT-3.5)"
    echo -e "${GREEN}2)${NC} Claude (Anthropic)"
    echo -e "${GREEN}3)${NC} GitHub Models"
    echo -e "${GREEN}4)${NC} Загрузить сохраненную конфигурацию"
    echo -e "${RED}0)${NC} Выход"
    echo ""
}

# Функция для сохранения конфигурации
save_config() {
    cat > "$CONFIG_FILE" <<EOF
PROVIDER="$PROVIDER"
API_KEY="$API_KEY"
MODEL_ID="$MODEL_ID"
EOF
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✓ Конфигурация сохранена${NC}"
}

# Функция для загрузки конфигурации
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo -e "${GREEN}✓ Конфигурация загружена${NC}"
        echo -e "${CYAN}Провайдер:${NC} $PROVIDER"
        echo -e "${CYAN}Модель:${NC} $MODEL_ID"
        return 0
    else
        echo -e "${RED}✗ Файл конфигурации не найден${NC}"
        return 1
    fi
}

# Функция для выбора провайдера
select_provider() {
    print_header
    print_menu
    
    read -p "Ваш выбор: " choice
    
    case $choice in
        1)
            PROVIDER="openai"
            echo -e "\n${CYAN}Выбран провайдер: OpenAI${NC}"
            ;;
        2)
            PROVIDER="claude"
            echo -e "\n${CYAN}Выбран провайдер: Claude (Anthropic)${NC}"
            ;;
        3)
            PROVIDER="github"
            echo -e "\n${CYAN}Выбран провайдер: GitHub Models${NC}"
            ;;
        4)
            if load_config; then
                return 0
            else
                sleep 2
                select_provider
                return
            fi
            ;;
        0)
            echo -e "${YELLOW}До свидания!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
            sleep 2
            select_provider
            return
            ;;
    esac
}

# Функция для ввода API ключа
input_api_key() {
    echo ""
    echo -e "${YELLOW}Введите API ключ для $PROVIDER:${NC}"
    read -s API_KEY
    echo -e "${GREEN}✓ API ключ принят${NC}"
}

# Функция для ввода ID модели
input_model_id() {
    echo ""
    echo -e "${YELLOW}Введите ID модели:${NC}"
    
    case $PROVIDER in
        openai)
            echo -e "${CYAN}Примеры: gpt-4, gpt-4-turbo, gpt-3.5-turbo${NC}"
            ;;
        claude)
            echo -e "${CYAN}Примеры: claude-3-5-sonnet-20241022, claude-3-opus-20240229${NC}"
            ;;
        github)
            echo -e "${CYAN}Примеры: gpt-4o, Phi-3-medium-128k-instruct${NC}"
            ;;
    esac
    
    read MODEL_ID
    echo -e "${GREEN}✓ Модель выбрана: $MODEL_ID${NC}"
}

# Функция для изменения настроек из чата
change_settings() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Настройки FixAdm                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Текущие настройки:${NC}"
    echo -e "  ${CYAN}Провайдер:${NC} $PROVIDER"
    echo -e "  ${CYAN}Модель:${NC} $MODEL_ID"
    echo -e "  ${CYAN}API ключ:${NC} ${API_KEY:0:10}...${API_KEY: -4}"
    echo ""
    echo -e "${YELLOW}Что вы хотите изменить?${NC}"
    echo -e "${GREEN}1)${NC} Провайдер"
    echo -e "${GREEN}2)${NC} API ключ"
    echo -e "${GREEN}3)${NC} ID модели"
    echo -e "${GREEN}4)${NC} Всё (провайдер, API, модель)"
    echo -e "${GREEN}0)${NC} Отмена"
    echo ""
    read -p "Ваш выбор: " settings_choice
    
    case $settings_choice in
        1)
            echo ""
            echo -e "${YELLOW}Выберите нового провайдера:${NC}"
            echo -e "${GREEN}1)${NC} OpenAI"
            echo -e "${GREEN}2)${NC} Claude"
            echo -e "${GREEN}3)${NC} GitHub Models"
            echo ""
            read -p "Ваш выбор: " provider_choice
            
            case $provider_choice in
                1)
                    PROVIDER="openai"
                    echo -e "${GREEN}✓ Провайдер изменен на: OpenAI${NC}"
                    ;;
                2)
                    PROVIDER="claude"
                    echo -e "${GREEN}✓ Провайдер изменен на: Claude${NC}"
                    ;;
                3)
                    PROVIDER="github"
                    echo -e "${GREEN}✓ Провайдер изменен на: GitHub Models${NC}"
                    ;;
                *)
                    echo -e "${RED}✗ Неверный выбор${NC}"
                    return
                    ;;
            esac
            
            # Очищаем историю разговора при смене провайдера
            clear_conversation
            echo -e "${YELLOW}История разговора очищена (новый провайдер)${NC}"
            ;;
            
        2)
            input_api_key
            # Очищаем историю разговора при смене API ключа
            clear_conversation
            echo -e "${YELLOW}История разговора очищена (новый API ключ)${NC}"
            ;;
            
        3)
            input_model_id
            # Очищаем историю разговора при смене модели
            clear_conversation
            echo -e "${YELLOW}История разговора очищена (новая модель)${NC}"
            ;;
            
        4)
            select_provider
            if [ -z "$API_KEY" ]; then
                input_api_key
            fi
            if [ -z "$MODEL_ID" ]; then
                input_model_id
            fi
            # Очищаем историю разговора при полной смене настроек
            clear_conversation
            echo -e "${YELLOW}История разговора очищена (новые настройки)${NC}"
            ;;
            
        0)
            echo -e "${YELLOW}Отмена${NC}"
            return
            ;;
            
        *)
            echo -e "${RED}✗ Неверный выбор${NC}"
            return
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Сохранить новые настройки? (y/n):${NC} "
    read -r save_choice
    if [[ $save_choice =~ ^[Yy]$ ]]; then
        save_config
    fi
    
    echo ""
    echo -e "${GREEN}✓ Настройки обновлены${NC}"
    echo -e "${CYAN}Новые настройки:${NC}"
    echo -e "  ${CYAN}Провайдер:${NC} $PROVIDER"
    echo -e "  ${CYAN}Модель:${NC} $MODEL_ID"
    echo ""
}

# Функция для загрузки истории разговора
load_conversation() {
    if [ -f "$CONVERSATION_FILE" ]; then
        cat "$CONVERSATION_FILE"
    else
        echo "[]"
    fi
}

# Функция для сохранения сообщения в историю
save_message() {
    local role="$1"
    local content="$2"
    
    local conversation=$(load_conversation)
    local new_message=$(jq -n --arg role "$role" --arg content "$content" '{role: $role, content: $content}')
    
    # Добавляем новое сообщение
    conversation=$(echo "$conversation" | jq ". += [$new_message]")
    
    # Оставляем только последние MAX_MESSAGES сообщений
    local count=$(echo "$conversation" | jq 'length')
    if [ "$count" -gt "$MAX_MESSAGES" ]; then
        local to_remove=$((count - MAX_MESSAGES))
        conversation=$(echo "$conversation" | jq ".[$to_remove:]")
    fi
    
    echo "$conversation" > "$CONVERSATION_FILE"
}

# Функция для очистки истории разговора
clear_conversation() {
    echo "[]" > "$CONVERSATION_FILE"
    echo -e "${GREEN}✓ История разговора очищена${NC}"
}

# Функция для получения истории в формате для API
get_conversation_history() {
    local conversation=$(load_conversation)
    echo "$conversation"
}

# Функция для вызова OpenAI API
call_openai() {
    local prompt="$1"
    
    # Получаем историю разговора
    local history=$(get_conversation_history)



















    
    # Формируем массив сообщений
    local messages="[{\"role\": \"system\", \"content\": $(echo "$SYSTEM_PROMPT" | jq -Rs .)}]"
    
    # Добавляем историю
    if [ "$history" != "[]" ]; then
        messages=$(echo "$messages" | jq ". += $(echo "$history")")
    fi
    
    # Добавляем текущее сообщение пользователя
    messages=$(echo "$messages" | jq ". += [{\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}]")
    
    local response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d "{
            \"model\": \"$MODEL_ID\",
            \"messages\": $messages,
            \"temperature\": 0.7
        }")
    
    echo "$response"
}

# Функция для вызова Claude API
call_claude() {
    local prompt="$1"
    
    # Получаем историю разговора
    local history=$(get_conversation_history)
    
    # Формируем массив сообщений для Claude
    local messages="[]"
    
    # Добавляем историю
    if [ "$history" != "[]" ]; then
        messages="$history"
    fi
    
    # Добавляем текущее сообщение пользователя
    messages=$(echo "$messages" | jq ". += [{\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}]")
    
    local response=$(curl -s https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d "{
            \"model\": \"$MODEL_ID\",
            \"max_tokens\": 4096,
            \"system\": $(echo "$SYSTEM_PROMPT" | jq -Rs .),
            \"messages\": $messages
        }")
    
    echo "$response"
}

# Функция для вызова GitHub Models API
call_github() {
    local prompt="$1"
    
    # Получаем историю разговора
    local history=$(get_conversation_history)
    
    # Формируем массив сообщений
    local messages="[{\"role\": \"system\", \"content\": $(echo "$SYSTEM_PROMPT" | jq -Rs .)}]"
    
    # Добавляем историю
    if [ "$history" != "[]" ]; then
        messages=$(echo "$messages" | jq ". += $(echo "$history")")
    fi
    
    # Добавляем текущее сообщение пользователя
    messages=$(echo "$messages" | jq ". += [{\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}]")
    
    local response=$(curl -s https://models.inference.ai.azure.com/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d "{
            \"model\": \"$MODEL_ID\",
            \"messages\": $messages,
            \"temperature\": 0.7
        }")
    
    echo "$response"
}

# Функция для извлечения JSON из текста
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
    
    # Метод 2: Используем jq для извлечения первого объекта
    # Пробуем найти JSON начиная с первой {
    local start_pos=$(echo "$text" | grep -b -o '{' | head -1 | cut -d: -f1)
    if [ -n "$start_pos" ]; then
        local json_part=$(echo "$text" | tail -c +$((start_pos + 1)))
        # Пробуем извлечь JSON с помощью jq
        local extracted=$(echo "$json_part" | jq -c '.' 2>/dev/null | head -1)
        if [ -n "$extracted" ] && echo "$extracted" | jq -e '.type' > /dev/null 2>&1; then
            echo "$extracted"
            return 0
        fi
    fi
    
    # Метод 3: Ищем {"type" и берем до ближайшей }
    local json=$(echo "$text" | grep -o '{"type"[^}]*}' | head -1)
    if [ -n "$json" ] && echo "$json" | jq -e '.type' > /dev/null 2>&1; then
        echo "$json"
        return 0
    fi
    
    # Не удалось извлечь JSON
    echo "$text"
    return 1
}

# Функция для парсинга ответа и извлечения контента
parse_response() {
    local response="$1"
    local content=""
    
    case $PROVIDER in
        openai|github)
            content=$(echo "$response" | jq -r '.choices[0].message.content // empty')
            ;;
        claude)
            content=$(echo "$response" | jq -r '.content[0].text // empty')
            ;;
    esac
    
    echo "$content"
}

# Функция для выполнения команды с подтверждением
execute_command() {
    local cmd="$1"
    local explanation="$2"
    
    echo -e "\n${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║ AI предлагает выполнить команду:${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}Команда:${NC} ${WHITE}$cmd${NC}"
    echo -e "${CYAN}Объяснение:${NC} $explanation"
    echo ""
    
    # Проверяем если это команда редактирования файла
    if [[ "$cmd" =~ (nano|vim|vi)\ (.+) ]]; then
        local editor="${BASH_REMATCH[1]}"
        local filepath=$(echo "$cmd" | grep -oP '(nano|vim|vi)\s+\K\S+' | head -1)
        
        # Убираем sudo если есть
        filepath=$(echo "$filepath" | sed 's/^sudo\s*//')
        
        echo -e "${CYAN}Обнаружено редактирование файла: $filepath${NC}"
        echo ""
        
        # Показываем содержимое файла ДО изменений
        if [ -f "$filepath" ]; then
            echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${BLUE}║ Содержимое файла ДО изменений:${NC}"
            echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
            cat "$filepath" 2>/dev/null | head -30
            if [ $(wc -l < "$filepath" 2>/dev/null) -gt 30 ]; then
                echo -e "${YELLOW}... (показаны первые 30 строк)${NC}"
            fi
            echo ""
        else
            echo -e "${YELLOW}Файл не существует, будет создан новый${NC}"
            echo ""
        fi
    fi
    
    echo -e "${YELLOW}Выполнить команду? (y/n/e - edit):${NC} "
    read -r confirm
    
    case $confirm in
        y|Y|yes|да)
            echo -e "${GREEN}→ Выполняю команду...${NC}\n"
            echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
            
            # Выполняем команду и сохраняем вывод
            local cmd_output=$(eval "$cmd" 2>&1)
            local exit_code=$?
            
            # Показываем вывод
            echo "$cmd_output" | while IFS= read -r line; do
                echo -e "${WHITE}║${NC} $line"
            done
            echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
            
            # Если это была команда редактирования, показываем результат
            if [[ "$cmd" =~ (nano|vim|vi)\ (.+) ]]; then
                local filepath=$(echo "$cmd" | grep -oP '(nano|vim|vi)\s+\K\S+' | head -1)
                filepath=$(echo "$filepath" | sed 's/^sudo\s*//')
                
                if [ -f "$filepath" ]; then
                    echo ""
                    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║ Содержимое файла ПОСЛЕ изменений:${NC}"
                    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
                    cat "$filepath" 2>/dev/null | head -30
                    if [ $(wc -l < "$filepath" 2>/dev/null) -gt 30 ]; then
                        echo -e "${YELLOW}... (показаны первые 30 строк)${NC}"
                    fi
                    echo ""
                fi
            fi
            
            if [ $exit_code -eq 0 ]; then
                echo -e "${GREEN}✓ Команда выполнена успешно${NC}\n"
                # Возвращаем вывод для передачи AI
                echo "$cmd_output"
                return 0
            else
                echo -e "${RED}✗ Команда завершилась с ошибкой (код: $exit_code)${NC}\n"
                # Возвращаем вывод с ошибкой для передачи AI
                echo "ОШИБКА (код $exit_code): $cmd_output"
                return 1
            fi
            ;;
        e|E|edit)
            echo -e "${CYAN}Введите исправленную команду:${NC}"
            read -e -i "$cmd" edited_cmd
            execute_command "$edited_cmd" "Отредактированная команда"
            ;;
        *)
            echo -e "${RED}✗ Команда отменена${NC}\n"
            echo "ОТМЕНЕНО: Пользователь отменил выполнение команды"
            return 1
            ;;
    esac
}

# Основная функция чата
start_chat() {
    print_header
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${WHITE}${BOLD}                    Чат запущен!                       ${NC}${GREEN}║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} Провайдер: ${CYAN}$PROVIDER${NC}"
    echo -e "${GREEN}║${NC} Модель: ${CYAN}$MODEL_ID${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Команды:${NC}"
    echo -e "  ${CYAN}/exit${NC} - выход из чата"
    echo -e "  ${CYAN}/clear${NC} - очистить экран"
    echo -e "  ${CYAN}/save${NC} - сохранить конфигурацию"
    echo -e "  ${CYAN}/reset${NC} - очистить историю разговора"
    echo -e "  ${CYAN}/settings${NC} - изменить настройки (провайдер, API, модель)"
    echo -e "  ${CYAN}/update${NC} - проверить и установить обновления"
    echo -e "  ${CYAN}/history${NC} - показать количество сообщений в памяти"
    echo -e "  ${CYAN}/help${NC} - показать помощь"
    echo ""
    
    # Создаем файлы если их нет
    touch "$HISTORY_FILE"
    if [ ! -f "$CONVERSATION_FILE" ]; then
        echo "[]" > "$CONVERSATION_FILE"
    fi
    
    local auto_continue=""
    local error_retry_count=0
    local max_retries=5
    
    while true; do
        # Если есть автоматическое продолжение, используем его
        if [ -n "$auto_continue" ]; then
            user_input="$auto_continue"
            auto_continue=""
            echo -e "${CYAN}→ AI автоматически продолжает работу...${NC}\n"
        else
            echo -e "${MAGENTA}┌─[${WHITE}Вы${MAGENTA}]${NC}"
            echo -e -n "${MAGENTA}└──>${NC} "
            read -e user_input
            
            # Сохраняем в историю
            echo "$user_input" >> "$HISTORY_FILE"
        fi
        
        # Обработка специальных команд
        case $user_input in
            /exit|/quit)
                echo -e "${YELLOW}Завершение работы...${NC}"
                exit 0
                ;;
            /clear)
                start_chat
                return
                ;;
            /save)
                save_config
                continue
                ;;
            /reset)
                clear_conversation
                continue
                ;;
            /settings)
                change_settings
                continue
                ;;
            /update)
                echo ""
                update_fixadm
                echo ""
                echo -e "${CYAN}Нажмите Enter для продолжения...${NC}"
                read
                continue
                ;;
            /history)
                local msg_count=$(cat "$CONVERSATION_FILE" | jq 'length')
                echo -e "${CYAN}Сообщений в памяти:${NC} $msg_count / $MAX_MESSAGES"
                echo ""
                continue
                ;;
            /help)
                echo -e "${CYAN}Доступные команды:${NC}"
                echo -e "  ${CYAN}/exit${NC} - выход из чата"
                echo -e "  ${CYAN}/clear${NC} - очистить экран"
                echo -e "  ${CYAN}/save${NC} - сохранить конфигурацию"
                echo -e "  ${CYAN}/reset${NC} - очистить историю разговора (AI забудет контекст)"
                echo -e "  ${CYAN}/settings${NC} - изменить настройки (провайдер, API ключ, модель)"
                echo -e "  ${CYAN}/update${NC} - проверить и установить обновления"
                echo -e "  ${CYAN}/history${NC} - показать количество сообщений в памяти"
                echo -e "  ${CYAN}/help${NC} - эта справка"
                echo ""
                echo -e "${YELLOW}Информация:${NC}"
                echo -e "  AI помнит последние $MAX_MESSAGES сообщений"
                echo -e "  Все команды требуют подтверждения перед выполнением"
                echo -e "  Вы можете отредактировать команду перед выполнением (опция 'e')"
                echo ""
                continue
                ;;
            "")
                continue
                ;;
        esac
        
        echo -e "${BLUE}┌─[${WHITE}AI думает...${BLUE}]${NC}"
        
        # Вызываем API в зависимости от провайдера
        local response=""
        case $PROVIDER in
            openai)
                response=$(call_openai "$user_input")
                ;;
            claude)
                response=$(call_claude "$user_input")
                ;;
            github)
                response=$(call_github "$user_input")
                ;;
        esac
        
        # Проверяем на ошибки API
        if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
            local error_msg=$(echo "$response" | jq -r '.error.message // .error')
            echo -e "${RED}✗ Ошибка API: $error_msg${NC}\n"
            
            # Показываем полный ответ для отладки
            if [ -n "$DEBUG" ] && [ "$DEBUG" = "1" ]; then
                echo -e "${YELLOW}[DEBUG] Полный ответ API:${NC}"
                echo "$response" | jq '.'
                echo ""
            fi
            continue
        fi
        
        # Парсим ответ
        local content=$(parse_response "$response")
        
        # Отладка: показываем сырой ответ если установлена переменная DEBUG
        if [ -n "$DEBUG" ] && [ "$DEBUG" = "1" ]; then
            echo -e "${YELLOW}[DEBUG] Сырой ответ API:${NC}"
            echo "$response" | jq '.' 2>/dev/null || echo "$response"
            echo ""
            echo -e "${YELLOW}[DEBUG] Извлеченный контент:${NC}"
            echo "$content"
            echo ""
        fi
        
        if [ -z "$content" ]; then
            echo -e "${RED}✗ Не удалось получить ответ от AI${NC}"
            echo -e "${YELLOW}Возможные причины:${NC}"
            echo -e "  - Неверный API ключ"
            echo -e "  - Недостаточно средств на аккаунте"
            echo -e "  - Проблемы с сетью"
            echo -e "  - Неверная модель: $MODEL_ID"
            echo ""
            echo -e "${CYAN}Включите отладку для деталей: DEBUG=1 fixadm${NC}\n"
            continue
        fi
        
        # Извлекаем JSON из ответа
        content=$(extract_json "$content")
        
        # Проверяем что это валидный JSON
        if ! echo "$content" | jq -e '.type' > /dev/null 2>&1; then
            echo -e "${RED}✗ AI вернула невалидный JSON${NC}"
            echo -e "${YELLOW}Ответ AI:${NC}"
            echo "$content" | head -10
            echo ""
            echo -e "${CYAN}AI должна отвечать ОДНИМ JSON объектом:${NC}"
            echo -e '  {"type": "command", "command": "...", "explanation": "..."}'
            echo -e '  или'
            echo -e '  {"type": "message", "content": "..."}'
            echo ""
            continue
        fi
        
        # Отладка: показываем что получилось после extract_json
        if [ -n "$DEBUG" ] && [ "$DEBUG" = "1" ]; then
            echo -e "${YELLOW}[DEBUG] После extract_json:${NC}"
            echo "$content"
            echo -e "${YELLOW}[DEBUG] Проверка jq:${NC}"
            if echo "$content" | jq -e '.type' > /dev/null 2>&1; then
                echo "✓ JSON валиден"
                echo "Тип: $(echo "$content" | jq -r '.type')"
            else
                echo "✗ JSON невалиден"
            fi
            echo ""
        fi
        
        # Сохраняем сообщения в историю
        save_message "user" "$user_input"
        save_message "assistant" "$content"
        
        # Пытаемся распарсить как JSON команду
        if echo "$content" | jq -e '.type' > /dev/null 2>&1; then
            local msg_type=$(echo "$content" | jq -r '.type')
            
            if [ "$msg_type" = "command" ]; then
                local cmd=$(echo "$content" | jq -r '.command')
                local explanation=$(echo "$content" | jq -r '.explanation')
                
                # Отладка: показываем извлеченные данные
                if [ -n "$DEBUG" ] && [ "$DEBUG" = "1" ]; then
                    echo -e "${YELLOW}[DEBUG] Извлеченная команда: $cmd${NC}"
                    echo -e "${YELLOW}[DEBUG] Извлеченное объяснение: $explanation${NC}"
                    echo ""
                fi
                
                # Проверяем что команда не пустая
                if [ -z "$cmd" ] || [ "$cmd" = "null" ]; then
                    echo -e "${RED}✗ Ошибка: AI не вернула команду${NC}\n"
                    continue
                fi
                
                echo -e "${BLUE}└─[${WHITE}AI${BLUE}]${NC}"
                
                # Отладка: перед вызовом execute_command
                if [ -n "$DEBUG" ] && [ "$DEBUG" = "1" ]; then
                    echo -e "${YELLOW}[DEBUG] Вызываю execute_command...${NC}"
                fi
                
                # Выполняем команду напрямую (не через $() чтобы не блокировать ввод)
                execute_command "$cmd" "$explanation"
                local cmd_exit_code=$?
                
                # Отладка: после execute_command
                if [ -n "$DEBUG" ] && [ "$DEBUG" = "1" ]; then
                    echo -e "${YELLOW}[DEBUG] execute_command завершена с кодом: $cmd_exit_code${NC}"
                fi
                
                # Добавляем результат выполнения в историю для AI
                if [ $cmd_exit_code -eq 0 ]; then
                    save_message "user" "Команда выполнена успешно"
                    # Сбрасываем счетчик ошибок при успехе
                    error_retry_count=0
                    last_error=""
                    # Автоматически продолжаем - отправляем сигнал AI продолжить
                    auto_continue="продолжай установку"
                    continue
                else
                    # Увеличиваем счетчик попыток
                    error_retry_count=$((error_retry_count + 1))
                    
                    if [ $error_retry_count -ge $max_retries ]; then
                        # Достигнут лимит попыток
                        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
                        echo -e "${RED}║ Достигнут лимит попыток исправления ($max_retries)        ║${NC}"
                        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
                        echo -e "${YELLOW}Последняя ошибка:${NC}"
                        echo -e "${CYAN}AI не смогла решить проблему автоматически.${NC}"
                        echo -e "${CYAN}Попробуйте:${NC}"
                        echo -e "  - Уточнить задачу"
                        echo -e "  - Проверить права доступа"
                        echo -e "  - Установить необходимые зависимости вручную"
                        echo ""
                        # Сбрасываем счетчик для следующей задачи
                        error_retry_count=0
                    else
                        # Продолжаем попытки
                        save_message "user" "Команда завершилась с ошибкой. Попытка $error_retry_count из $max_retries. ВАЖНО: Попробуй ДРУГОЙ подход!"
                        # При ошибке продолжаем - AI должна исправить
                        auto_continue="Команда завершилась с ошибкой. Попытка $error_retry_count из $max_retries. Проанализируй ошибку и попробуй ДРУГОЙ способ решения задачи. Не повторяй ту же команду!"
                        continue
                    fi
                fi
                
            elif [ "$msg_type" = "message" ]; then
                local message=$(echo "$content" | jq -r '.content')
                echo -e "${BLUE}└─[${WHITE}AI${BLUE}]${NC}"
                echo -e "${WHITE}$message${NC}\n"
                
                # Проверяем является ли это финальным сообщением с инструкциями
                if echo "$message" | grep -qi "установка завершена\|установлен и запущен\|готово\|доступ:\|команды для управления"; then
                    # Это финальная инструкция, не продолжаем автоматически
                    :
                # Проверяем является ли это уточняющим вопросом
                elif echo "$message" | grep -qi "уточните\|что именно\|какой\|какую\|пожалуйста, укажите\|не могу выполнить без\|необходимо указать"; then
                    # Это уточняющий вопрос, не продолжаем автоматически
                    :
                else
                    # Это промежуточное информационное сообщение, продолжаем
                    auto_continue="продолжай"
                    continue
                fi
            fi
        else
            # Обычный текстовый ответ
            echo -e "${BLUE}└─[${WHITE}AI${BLUE}]${NC}"
            echo -e "${WHITE}$content${NC}\n"
        fi
    done
}

# Главная функция
main() {
    # Проверяем наличие необходимых утилит
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Ошибка: требуется утилита 'jq'${NC}"
        echo -e "${YELLOW}Установите: sudo apt install jq${NC}"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Ошибка: требуется утилита 'curl'${NC}"
        echo -e "${YELLOW}Установите: sudo apt install curl${NC}"
        exit 1
    fi
    
    # Обработка аргументов командной строки
    if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
        update_fixadm
        exit 0
    fi
    
    if [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
        echo "FixAdm v$CURRENT_VERSION"
        exit 0
    fi
    
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "FixAdm v$CURRENT_VERSION - AI-powered администратор для Ubuntu"
        echo ""
        echo "Использование:"
        echo "  fixadm              Запустить интерактивный чат"
        echo "  fixadm --update     Проверить и установить обновления"
        echo "  fixadm --version    Показать версию"
        echo "  fixadm --help       Показать эту справку"
        echo ""
        echo "Репозиторий: $REPO_URL"
        exit 0
    fi
    
    # Проверка обновлений при запуске
    check_for_updates
    
    # Выбор провайдера
    select_provider
    
    # Если конфигурация не была загружена, запрашиваем данные
    if [ -z "$API_KEY" ]; then
        input_api_key
    fi
    
    if [ -z "$MODEL_ID" ]; then
        input_model_id
    fi
    
    # Предлагаем сохранить конфигурацию
    echo ""
    echo -e "${YELLOW}Сохранить конфигурацию для будущего использования? (y/n):${NC} "
    read -r save_choice
    if [[ $save_choice =~ ^[Yy]$ ]]; then
        save_config
    fi
    
    sleep 1
    
    # Запускаем чат
    start_chat
}

# Запуск программы
main
