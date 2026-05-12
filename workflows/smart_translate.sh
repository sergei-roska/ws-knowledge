#!/bin/bash

# === SETTINGS ===
MODEL="translategemma:12b"  # 4b for speed, 12b for maximum quality
STATE_FILE="/tmp/last_lang"
DEFAULT_TARGET_NAME="English"
DEFAULT_TARGET_CODE="en"

# --- 1. Get text from buffer (X11 or Wayland) ---
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    TEXT=$(wl-paste)
else
    TEXT=$(xclip -o -selection clipboard)
fi

if [ -z "$TEXT" ]; then
    notify-send "Translator" "Clipboard is empty"
    exit 1
fi

# --- 2. Translation direction logic ---
if [[ "$TEXT" =~ [а-яА-ЯёЁ] ]]; then
    # TEXT IN RUSSIAN -> TRANSLATE TO (EN or RO)
    SOURCE_LANG="Russian"
    SOURCE_CODE="ru"
    
    if [ -f "$STATE_FILE" ]; then
        # Read saved language from "memory" (format Name:code)
        SAVED_DATA=$(cat "$STATE_FILE")
        TARGET_LANG=${SAVED_DATA%:*}
        TARGET_CODE=${SAVED_DATA#*:}
    else
        TARGET_LANG=$DEFAULT_TARGET_NAME
        TARGET_CODE=$DEFAULT_TARGET_CODE
    fi
else
    # TEXT NOT IN RUSSIAN -> TRANSLATE TO RUSSIAN
    TARGET_LANG="Russian"
    TARGET_CODE="ru"
    
    # Try to determine if it's Romanian or English by special characters
    if [[ "$TEXT" =~ [ăâîșțĂÂÎȘȚ] ]]; then
        SOURCE_LANG="Romanian"
        SOURCE_CODE="ro"
        echo "Romanian:ro" > "$STATE_FILE"
    else
        SOURCE_LANG="English"
        SOURCE_CODE="en"
        echo "English:en" > "$STATE_FILE"
    fi
fi

# --- 3. Form professional prompt ---
SYSTEM_PROMPT="You are a professional $SOURCE_LANG ($SOURCE_CODE) to $TARGET_LANG ($TARGET_CODE) translator. Your goal is to accurately convey the meaning and nuances of the original $SOURCE_LANG text while adhering to $TARGET_LANG grammar, vocabulary, and cultural sensitivities. Produce only the $TARGET_LANG translation, without any additional explanations or commentary. Please translate the following $SOURCE_LANG text into $TARGET_LANG:"

# --- 4. Request to Ollama ---
notify-send "Translating to $TARGET_LANG..." "Wait a second"

# Safely pack into JSON via jq
JSON_DATA=$(jq -n --arg p "$SYSTEM_PROMPT" --arg t "$TEXT" --arg m "$MODEL" \
    '{model: $m, prompt: ($p + "\n\n" + $t), stream: false}')

RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate -d "$JSON_DATA" | jq -r '.response' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# --- 5. Result to buffer and notification ---
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    echo -n "$RESPONSE" | wl-copy
else
    echo -n "$RESPONSE" | xclip -selection clipboard
fi

notify-send "Done! ($TARGET_LANG)" "$RESPONSE"

