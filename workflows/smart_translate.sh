#!/bin/bash

# === CONFIG ===
MODEL="translategemma:12b"
STATE_FILE="/tmp/last_lang"

# 1. Load State
IFS=":" read -r STATE_NAME STATE_CODE < <(cat "$STATE_FILE" 2>/dev/null || echo "English:en")

# 2. Handle Arguments (Manual override)
case "$1" in
    ro) STATE_NAME="Romanian"; STATE_CODE="ro" ;;
    en) STATE_NAME="English"; STATE_CODE="en" ;;
esac
[[ -n "$1" ]] && echo "$STATE_NAME:$STATE_CODE" > "$STATE_FILE"

# 3. Get Input
TEXT=$( [[ "$XDG_SESSION_TYPE" == "wayland" ]] && wl-paste || xclip -o -selection clipboard )
[[ -z "${TEXT//[[:space:]]/}" ]] && { notify-send "Translator" "Clipboard is empty"; exit 1; }

# 4. Determine Direction
if [[ "$TEXT" =~ [а-яА-ЯёЁ] ]]; then
    # Russian -> Saved Context
    SL="Russian"; SC="ru"; TL="$STATE_NAME"; TC="$STATE_CODE"
else
    # Foreign -> Russian
    TL="Russian"; TC="ru"
    [[ "$1" == "ro" || "$TEXT" =~ [ăâîșțĂÂÎȘȚşţŞŢ] ]] && { SL="Romanian"; SC="ro"; } || { SL="English"; SC="en"; }
    echo "$SL:$SC" > "$STATE_FILE"
fi

# 5. Translation
notify-send "Translating to $TL..." "Wait a second"

# Construct JSON via jq with prompt interpolation
JSON=$(jq -n --arg m "$MODEL" --arg t "$TEXT" --arg sl "$SL" --arg sc "$SC" --arg tl "$TL" --arg tc "$TC" \
    '{model: $m, prompt: "You are a professional \($sl) (\($sc)) to \($tl) (\($tc)) translator. Convey meaning and nuances while adhering to grammar. Produce ONLY the \($tl) translation.\n\n\($t)", stream: false}')

RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate -d "$JSON" | jq -r '.response' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# 6. Output
[[ "$XDG_SESSION_TYPE" == "wayland" ]] && echo -n "$RESPONSE" | wl-copy || echo -n "$RESPONSE" | xclip -selection clipboard
notify-send "Done! ($TL)" "$RESPONSE"
