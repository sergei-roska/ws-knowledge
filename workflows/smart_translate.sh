#!/bin/bash

# === SETTINGS ===
MODEL="translategemma:12b"  # 4b for speed, 12b for maximum quality
STATE_FILE="/tmp/last_lang"
DEFAULT_TARGET_NAME="English"
DEFAULT_TARGET_CODE="en"

# --- 1. Load current state (defaults to English if no file) ---
if [ -f "$STATE_FILE" ]; then
    SAVED_DATA=$(cat "$STATE_FILE")
    STATE_NAME=${SAVED_DATA%:*}
    STATE_CODE=${SAVED_DATA#*:}
else
    STATE_NAME=$DEFAULT_TARGET_NAME
    STATE_CODE=$DEFAULT_TARGET_CODE
fi

# --- 2. Handle manual override via argument (e.g. smart_translate.sh ro) ---
MANUAL_LANG=""
if [ -n "$1" ]; then
    case "$1" in
        ro) STATE_NAME="Romanian"; STATE_CODE="ro"; MANUAL_LANG="ro" ;;
        en) STATE_NAME="English"; STATE_CODE="en"; MANUAL_LANG="en" ;;
    esac
    # Save the forced language context for future Russian translations
    echo "$STATE_NAME:$STATE_CODE" > "$STATE_FILE"
fi

# --- 3. Get text from buffer (X11 or Wayland) ---
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    TEXT=$(wl-paste)
else
    TEXT=$(xclip -o -selection clipboard)
fi

if [ -z "$TEXT" ]; then
    notify-send "Translator" "Clipboard is empty"
    exit 1
fi

# --- 4. Translation direction logic ---
if [[ "$TEXT" =~ [а-яА-ЯёЁ] ]]; then
    # TEXT IN RUSSIAN -> TRANSLATE TO (STATE: EN or RO)
    SOURCE_LANG="Russian"
    SOURCE_CODE="ru"
    TARGET_LANG="$STATE_NAME"
    TARGET_CODE="$STATE_CODE"
else
    # TEXT NOT IN RUSSIAN -> TRANSLATE TO RUSSIAN
    TARGET_LANG="Russian"
    TARGET_CODE="ru"
    
    # Determine source language: default to English, override if Romanian is detected or forced
    if [ "$MANUAL_LANG" == "ro" ] || [[ "$TEXT" =~ [ăâîșțĂÂÎȘȚşţŞŢ] ]]; then
        SOURCE_LANG="Romanian"
        SOURCE_CODE="ro"
    else
        SOURCE_LANG="English"
        SOURCE_CODE="en"
    fi
    
    # Save the detected source for the next "from Russian" translation
    echo "$SOURCE_LANG:$SOURCE_CODE" > "$STATE_FILE"
fi

# --- 5. Form professional prompt ---
SYSTEM_PROMPT="You are a professional $SOURCE_LANG ($SOURCE_CODE) to $TARGET_LANG ($TARGET_CODE) translator. Your goal is to accurately convey the meaning and nuances of the original $SOURCE_LANG text while adhering to $TARGET_LANG grammar, vocabulary, and cultural sensitivities. Produce only the $TARGET_LANG translation, without any additional explanations or commentary. Please translate the following $SOURCE_LANG text into $TARGET_LANG:"

# --- 6. Request to Ollama ---
notify-send "Translating to $TARGET_LANG..." "Wait a second"

# Safely pack into JSON via jq
JSON_DATA=$(jq -n --arg p "$SYSTEM_PROMPT" --arg t "$TEXT" --arg m "$MODEL" \
    '{model: $m, prompt: ($p + "\n\n" + $t), stream: false}')

RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate -d "$JSON_DATA" | jq -r '.response' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# --- 7. Result to buffer and notification ---
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    echo -n "$RESPONSE" | wl-copy
else
    echo -n "$RESPONSE" | xclip -selection clipboard
fi

notify-send "Done! ($TARGET_LANG)" "$RESPONSE"

