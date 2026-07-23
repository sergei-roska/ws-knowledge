#!/bin/bash

notify() {
    local title="$1"
    local body="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$body"
    fi
}

fatal() {
    local msg="$1"
    echo "$msg" >&2
    notify "Translator Error" "$msg"
    exit 1
}

require_cmd() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 || fatal "Missing required dependency: $cmd"
}

can_reach_google_api() {
    curl --silent --head --max-time 3 --connect-timeout 2 \
        "https://generativelanguage.googleapis.com" >/dev/null 2>&1
}

can_reach_ollama_api() {
    curl --silent --max-time 2 --connect-timeout 1 \
        "http://localhost:11434/api/tags" >/dev/null 2>&1
}

# === SETTINGS ===
# PROVIDER: "google" or "ollama"
PROVIDER="${PROVIDER:-google}"
MODEL_USED="n/a"
LAST_ERROR=""
RESPONSE=""
TITLE="Translator"
STATE_FILE="/tmp/last_lang"

case "$PROVIDER" in
    google)
        # Cloud models in fallback order (first is primary)
        GOOGLE_MODELS=("gemini-3.5-live-translate" "gemini-3.5-flash-lite" "gemma-4-31b-it" "gemma-4-26b-a4b-it")
        # Local fallback model if cloud is unavailable / quota exceeded
        LOCAL_FALLBACK_MODEL="translategemma:12b"
        MODEL="${GOOGLE_MODELS[0]}"
        API_KEY_FILE="$HOME/.google_api_key"
        TITLE="Cloud (${MODEL})"
        ;;
    ollama)
        MODEL="${MODEL:-translategemma:12b}"
        TITLE="Local (${MODEL})"
        ;;
    *)
        fatal "Unsupported PROVIDER value: '$PROVIDER' (expected: google or ollama)"
        ;;
esac

# Offline-aware pre-fallback: switch to local before key checks/cloud calls.
if [ "$PROVIDER" == "google" ] && ! can_reach_google_api; then
    LAST_ERROR="Google API is unreachable (network offline or blocked)"
    PROVIDER="ollama"
    MODEL="$LOCAL_FALLBACK_MODEL"
    TITLE="Local (${MODEL})"
    notify "$TITLE" "Google API is unreachable. Switching directly to local fallback model ${MODEL}."
fi

# --- 1. Get API Key (if needed) ---
if [ "$PROVIDER" == "google" ]; then
    if [ ! -f "$API_KEY_FILE" ]; then
        fatal "API key file not found at $API_KEY_FILE"
    fi
    mapfile -t API_KEY_LINES < <(grep -v '^[[:space:]]*#' "$API_KEY_FILE" | sed '/^[[:space:]]*$/d')
    if [ "${#API_KEY_LINES[@]}" -eq 0 ]; then
        fatal "API key file is empty (after removing comments/blank lines): $API_KEY_FILE"
    fi
    if [ "${#API_KEY_LINES[@]}" -gt 1 ]; then
        fatal "API key file contains multiple non-empty entries. Keep exactly one key in $API_KEY_FILE"
    fi
    API_KEY=$(printf '%s' "${API_KEY_LINES[0]}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$API_KEY" ] || fatal "Parsed API key is empty in $API_KEY_FILE"
fi

# --- 2. Load State & Override ---
IFS=":" read -r STATE_NAME STATE_CODE < <(cat "$STATE_FILE" 2>/dev/null || echo "English:en")

case "$1" in
    ro) STATE_NAME="Romanian"; STATE_CODE="ro" ;;
    en) STATE_NAME="English"; STATE_CODE="en" ;;
esac
[[ -n "$1" ]] && echo "$STATE_NAME:$STATE_CODE" > "$STATE_FILE"

# --- 3. Get Input Clipboard Text ---
require_cmd curl
require_cmd jq

if [ -n "$WAYLAND_DISPLAY" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    if command -v wl-paste >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1; then
        CLIPBOARD_BACKEND="wayland"
    elif command -v xclip >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        CLIPBOARD_BACKEND="x11"
    else
        fatal "No compatible clipboard tool found for Wayland session (need wl-clipboard or xclip with DISPLAY)"
    fi
elif [ -n "$DISPLAY" ]; then
    if command -v xclip >/dev/null 2>&1; then
        CLIPBOARD_BACKEND="x11"
    elif command -v wl-paste >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1; then
        CLIPBOARD_BACKEND="wayland"
    else
        fatal "No compatible clipboard tool found for X11 session (need xclip or wl-clipboard)"
    fi
else
    fatal "Unable to detect graphical session (missing WAYLAND_DISPLAY/XDG_SESSION_TYPE/DISPLAY)"
fi

if [ "$CLIPBOARD_BACKEND" == "wayland" ]; then
    if ! TEXT=$(wl-paste 2>/dev/null); then
        fatal "Failed to read clipboard via wl-paste"
    fi
else
    if ! TEXT=$(xclip -o -selection clipboard 2>/dev/null); then
        fatal "Failed to read clipboard via xclip"
    fi
fi

if [ -z "${TEXT//[[:space:]]/}" ]; then
    notify "$TITLE" "Clipboard is empty"
    exit 1
fi

# --- 4. Determine Direction ---
if [[ "$TEXT" =~ [а-яА-ЯёЁ] ]]; then
    # Russian -> Saved Context
    SL="Russian"; SC="ru"; TL="$STATE_NAME"; TC="$STATE_CODE"
else
    # Foreign -> Russian
    TL="Russian"; TC="ru"
    [[ "$1" == "ro" || "$TEXT" =~ [ăâîșțĂÂÎȘȚşţŞŢ] ]] && { SL="Romanian"; SC="ro"; } || { SL="English"; SC="en"; }
    echo "$SL:$SC" > "$STATE_FILE"
fi

# --- 5. Construct Prompt ---
PROMPT="You are a professional ${SL} (${SC}) to ${TL} (${TC}) translator. Convey meaning and nuances while adhering to grammar. Produce ONLY the ${TL} translation.

${TEXT}"

# --- 6. Send Request ---
notify "$TITLE" "Translating to $TL..."

TRANSLATED_TEXT=""

if [ "$PROVIDER" == "google" ]; then
    JSON_DATA=$(jq -n --arg t "$PROMPT" '{contents: [{parts: [{text: $t}]}]}')
    for M in "${GOOGLE_MODELS[@]}"; do
        TITLE="Cloud (${M})"
        HTTP_RESPONSE=$(curl --silent --show-error --max-time 45 --connect-timeout 10 -w $'\n%{http_code}' -X POST "https://generativelanguage.googleapis.com/v1beta/models/${M}:generateContent" \
            -H 'Content-Type: application/json' \
            -H "x-goog-api-key: ${API_KEY}" \
            -d "$JSON_DATA")
        CURL_EXIT=$?
        if [ "$CURL_EXIT" -ne 0 ]; then
            LAST_ERROR="Model $M request failed (curl exit $CURL_EXIT)"
            echo "$LAST_ERROR, trying next..." >&2
            continue
        fi
        HTTP_CODE="${HTTP_RESPONSE##*$'\n'}"
        RESPONSE="${HTTP_RESPONSE%$'\n'*}"
        if ! [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
            LAST_ERROR="Model $M returned HTTP $HTTP_CODE"
            if echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
                API_ERR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
                [ -n "$API_ERR" ] && LAST_ERROR="${LAST_ERROR}: ${API_ERR}"
            fi
            echo "$LAST_ERROR, trying next..." >&2
            continue
        fi
        if ! echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
            LAST_ERROR="Model $M returned invalid JSON"
            echo "$LAST_ERROR, trying next..." >&2
            continue
        fi

        # Extract only the part that is NOT a thought
        TRANSLATED_TEXT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[] | select(.thought != true) | .text')

        if [ -n "$TRANSLATED_TEXT" ] && [ "$TRANSLATED_TEXT" != "null" ]; then
            MODEL_USED="$M"
            TITLE="Cloud (${MODEL_USED})"
            break
        fi
        LAST_ERROR="Model $M returned empty translation"
        echo "$LAST_ERROR, trying next..." >&2
    done

    # AUTOMATIC FALLBACK TO OLLAMA IF CLOUD FAILED
    if [ -z "$TRANSLATED_TEXT" ] || [ "$TRANSLATED_TEXT" == "null" ]; then
        PROVIDER="ollama"
        MODEL="$LOCAL_FALLBACK_MODEL"
        TITLE="Local (${MODEL})"
        notify "$TITLE" "Cloud failed. Switching to local fallback model ${MODEL}."
    fi
fi

if [ "$PROVIDER" == "ollama" ]; then
    TITLE="Local (${MODEL})"
    if ! can_reach_ollama_api; then
        fatal "Local Ollama API is unreachable at http://localhost:11434. Start Ollama and ensure model '${MODEL}' is available."
    fi
    JSON_DATA=$(jq -n --arg m "$MODEL" --arg t "$TEXT" --arg sl "$SL" --arg sc "$SC" --arg tl "$TL" --arg tc "$TC" \
        '{model: $m, prompt: "You are a professional \($sl) (\($sc)) to \($tl) (\($tc)) translator. Convey meaning and nuances while adhering to grammar. Produce ONLY the \($tl) translation.\n\n\($t)", stream: false}')
    HTTP_RESPONSE=$(curl --silent --show-error --max-time 45 --connect-timeout 10 -w $'\n%{http_code}' -X POST "http://localhost:11434/api/generate" \
        -H 'Content-Type: application/json' \
        -d "$JSON_DATA")
    CURL_EXIT=$?
    if [ "$CURL_EXIT" -ne 0 ]; then
        LAST_ERROR="Local Ollama request failed (curl exit $CURL_EXIT)"
    else
        HTTP_CODE="${HTTP_RESPONSE##*$'\n'}"
        RESPONSE="${HTTP_RESPONSE%$'\n'*}"
        if ! [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
            LAST_ERROR="Local Ollama returned HTTP $HTTP_CODE"
        elif ! echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
            LAST_ERROR="Local Ollama returned invalid JSON"
        else
            TRANSLATED_TEXT=$(echo "$RESPONSE" | jq -r '.response')
            if [ -n "$TRANSLATED_TEXT" ] && [ "$TRANSLATED_TEXT" != "null" ]; then
                MODEL_USED="$MODEL"
                TITLE="Local (${MODEL_USED})"
            else
                LAST_ERROR="Local model returned empty translation"
            fi
        fi
    fi
fi

# --- 7. Result Verification ---
if [ -z "$TRANSLATED_TEXT" ] || [ "$TRANSLATED_TEXT" == "null" ]; then
    echo "Raw response from last attempt ($MODEL_USED):" >&2
    if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
        echo "$RESPONSE" | jq . >&2
        ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message // .error // "Critical error: All providers failed"')
    else
        [ -n "$RESPONSE" ] && echo "$RESPONSE" >&2
        ERROR_MSG="Critical error: All providers failed"
    fi
    [ -n "$LAST_ERROR" ] && ERROR_MSG="${ERROR_MSG}. Last error: ${LAST_ERROR}"
    fatal "$ERROR_MSG"
fi

TRANSLATED_TEXT=$(printf '%s' "$TRANSLATED_TEXT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Put to clipboard
if [ "$CLIPBOARD_BACKEND" == "wayland" ]; then
    if ! echo -n "$TRANSLATED_TEXT" | wl-copy; then
        fatal "Failed to copy translated text via wl-copy"
    fi
else
    if ! echo -n "$TRANSLATED_TEXT" | xclip -selection clipboard; then
        fatal "Failed to copy translated text via xclip"
    fi
fi

# FINAL NOTIFICATION
notify "Done! (${MODEL_USED})" "$TRANSLATED_TEXT"
