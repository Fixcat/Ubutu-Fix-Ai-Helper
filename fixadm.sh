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

# Функция для красивого вывода заголовка
print_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                        FixAdm v1.1                     ${NC}${CYAN}║${NC}"
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
    local system_prompt="Ты - FixAdm, AI администратор Linux систем. Ты помогаешь пользователю администрировать Ubuntu сервер. 

КРИТИЧЕСКИ ВАЖНЫЕ ПРАВИЛА:

1. НИКОГДА не используй 'sudo apt update' или 'apt update' - на этой системе проблемы с репозиториями. Сразу устанавливай: sudo apt install -y <пакет>

2. НИКОГДА не используй интерактивные редакторы (nano, vim, vi, emacs) - они зависают в этой среде!

3. ДЛЯ РЕДАКТИРОВАНИЯ ФАЙЛОВ используй ТОЛЬКО эти методы:

   a) Создание нового файла:
      cat << 'EOF' | sudo tee /path/to/file
      содержимое
      файла
      EOF

   b) Добавление в конец файла:
      echo 'новая строка' | sudo tee -a /path/to/file

   c) Замена текста в файле:
      sudo sed -i 's/старый текст/новый текст/g' /path/to/file

   d) Замена целой строки:
      sudo sed -i '/строка для поиска/c\\новая строка' /path/to/file

   e) Вставка строки после определенной строки:
      sudo sed -i '/после этой строки/a\\новая строка' /path/to/file

   f) Удаление строки:
      sudo sed -i '/строка для удаления/d' /path/to/file

4. ВСЕГДА показывай содержимое файла после изменения:
   cat /path/to/file

5. Для сложных конфигов - делай пошагово: создай файл, потом добавляй строки по одной.

ПРИМЕР правильной работы с конфигом:
Вместо: sudo nano /etc/fail2ban/jail.local
Делай:
1) cat << 'EOF' | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
EOF

2) echo '[sshd]' | sudo tee -a /etc/fail2ban/jail.local
3) echo 'enabled = true' | sudo tee -a /etc/fail2ban/jail.local
4) cat /etc/fail2ban/jail.local  # показать результат

Когда нужно выполнить команду, отвечай в формате JSON: {\"type\": \"command\", \"command\": \"команда\", \"explanation\": \"что делаем\"}. Когда даешь обычный ответ: {\"type\": \"message\", \"content\": \"текст\"}."



















    
    # Формируем массив сообщений
    local messages="[{\"role\": \"system\", \"content\": $(echo "$system_prompt" | jq -Rs .)}]"
    
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
    local system_prompt="Ты - FixAdm, AI администратор Linux систем. Ты помогаешь пользователю администрировать Ubuntu сервер. 

КРИТИЧЕСКИ ВАЖНЫЕ ПРАВИЛА:

1. НИКОГДА не используй 'sudo apt update' или 'apt update' - на этой системе проблемы с репозиториями. Сразу устанавливай: sudo apt install -y <пакет>

2. НИКОГДА не используй интерактивные редакторы (nano, vim, vi, emacs) - они зависают в этой среде!

3. ДЛЯ РЕДАКТИРОВАНИЯ ФАЙЛОВ используй ТОЛЬКО эти методы:

   a) Создание нового файла:
      cat << 'EOF' | sudo tee /path/to/file
      содержимое
      файла
      EOF

   b) Добавление в конец файла:
      echo 'новая строка' | sudo tee -a /path/to/file

   c) Замена текста в файле:
      sudo sed -i 's/старый текст/новый текст/g' /path/to/file

   d) Замена целой строки:
      sudo sed -i '/строка для поиска/c\\новая строка' /path/to/file

   e) Вставка строки после определенной строки:
      sudo sed -i '/после этой строки/a\\новая строка' /path/to/file

   f) Удаление строки:
      sudo sed -i '/строка для удаления/d' /path/to/file

4. ВСЕГДА показывай содержимое файла после изменения:
   cat /path/to/file

5. Для сложных конфигов - делай пошагово: создай файл, потом добавляй строки по одной.

ПРИМЕР правильной работы с конфигом:
Вместо: sudo nano /etc/fail2ban/jail.local
Делай:
1) cat << 'EOF' | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
EOF

2) echo '[sshd]' | sudo tee -a /etc/fail2ban/jail.local
3) echo 'enabled = true' | sudo tee -a /etc/fail2ban/jail.local
4) cat /etc/fail2ban/jail.local  # показать результат

Когда нужно выполнить команду, отвечай в формате JSON: {\"type\": \"command\", \"command\": \"команда\", \"explanation\": \"что делаем\"}. Когда даешь обычный ответ: {\"type\": \"message\", \"content\": \"текст\"}."
    
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
            \"system\": $(echo "$system_prompt" | jq -Rs .),
            \"messages\": $messages
        }")
    
    echo "$response"
}

# Функция для вызова GitHub Models API
call_github() {
    local prompt="$1"
    local system_prompt="Ты - FixAdm, AI администратор Linux систем. Ты помогаешь пользователю администрировать Ubuntu сервер. 

КРИТИЧЕСКИ ВАЖНЫЕ ПРАВИЛА:

1. НИКОГДА не используй 'sudo apt update' или 'apt update' - на этой системе проблемы с репозиториями. Сразу устанавливай: sudo apt install -y <пакет>

2. НИКОГДА не используй интерактивные редакторы (nano, vim, vi, emacs) - они зависают в этой среде!

3. ДЛЯ РЕДАКТИРОВАНИЯ ФАЙЛОВ используй ТОЛЬКО эти методы:

   a) Создание нового файла:
      cat << 'EOF' | sudo tee /path/to/file
      содержимое
      файла
      EOF

   b) Добавление в конец файла:
      echo 'новая строка' | sudo tee -a /path/to/file

   c) Замена текста в файле:
      sudo sed -i 's/старый текст/новый текст/g' /path/to/file

   d) Замена целой строки:
      sudo sed -i '/строка для поиска/c\\новая строка' /path/to/file

   e) Вставка строки после определенной строки:
      sudo sed -i '/после этой строки/a\\новая строка' /path/to/file

   f) Удаление строки:
      sudo sed -i '/строка для удаления/d' /path/to/file

4. ВСЕГДА показывай содержимое файла после изменения:
   cat /path/to/file

5. Для сложных конфигов - делай пошагово: создай файл, потом добавляй строки по одной.

ПРИМЕР правильной работы с конфигом:
Вместо: sudo nano /etc/fail2ban/jail.local
Делай:
1) cat << 'EOF' | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
EOF

2) echo '[sshd]' | sudo tee -a /etc/fail2ban/jail.local
3) echo 'enabled = true' | sudo tee -a /etc/fail2ban/jail.local
4) cat /etc/fail2ban/jail.local  # показать результат

Когда нужно выполнить команду, отвечай в формате JSON: {\"type\": \"command\", \"command\": \"команда\", \"explanation\": \"что делаем\"}. Когда даешь обычный ответ: {\"type\": \"message\", \"content\": \"текст\"}."
    
    # Получаем историю разговора
    local history=$(get_conversation_history)
    
    # Формируем массив сообщений
    local messages="[{\"role\": \"system\", \"content\": $(echo "$system_prompt" | jq -Rs .)}]"
    
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
            eval "$cmd" 2>&1 | while IFS= read -r line; do
                echo -e "${WHITE}║${NC} $line"
            done
            local exit_code=${PIPESTATUS[0]}
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
                return 0
            else
                echo -e "${RED}✗ Команда завершилась с ошибкой (код: $exit_code)${NC}\n"
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
    echo -e "  ${CYAN}/history${NC} - показать количество сообщений в памяти"
    echo -e "  ${CYAN}/help${NC} - показать помощь"
    echo ""
    
    # Создаем файлы если их нет
    touch "$HISTORY_FILE"
    if [ ! -f "$CONVERSATION_FILE" ]; then
        echo "[]" > "$CONVERSATION_FILE"
    fi
    
    while true; do
        echo -e "${MAGENTA}┌─[${WHITE}Вы${MAGENTA}]${NC}"
        echo -e -n "${MAGENTA}└──>${NC} "
        read -e user_input
        
        # Сохраняем в историю
        echo "$user_input" >> "$HISTORY_FILE"
        
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
            continue
        fi
        
        # Парсим ответ
        local content=$(parse_response "$response")
        
        if [ -z "$content" ]; then
            echo -e "${RED}✗ Не удалось получить ответ от AI${NC}\n"
            continue
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
                
                echo -e "${BLUE}└─[${WHITE}AI${BLUE}]${NC}"
                execute_command "$cmd" "$explanation"
            elif [ "$msg_type" = "message" ]; then
                local message=$(echo "$content" | jq -r '.content')
                echo -e "${BLUE}└─[${WHITE}AI${BLUE}]${NC}"
                echo -e "${WHITE}$message${NC}\n"
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
