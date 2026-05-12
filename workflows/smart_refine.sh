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
    notify "Refiner Error" "$msg"
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
TITLE="Refiner"

# Choose model based on provider
case "$PROVIDER" in
    google)
        # Cloud models in fallback order (first is primary)
        GOOGLE_MODELS=("gemini-3.1-flash-lite-preview" "gemma-4-31b-it" "gemma-4-26b-a4b-it")
        # Local fallback model if cloud is unavailable / quota exceeded
        LOCAL_FALLBACK_MODEL="gemma4:e4b"
        MODEL="${GOOGLE_MODELS[0]}"
        API_KEY_FILE="$HOME/.google_api_key"
        TITLE="Cloud (${MODEL})"
        ;;
    ollama)
        MODEL="${MODEL:-gemma4:e4b}"
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

# --- 2. Get text from buffer (X11 or Wayland) ---
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

if [ -z "$TEXT" ]; then
    notify "$TITLE" "Clipboard is empty"
    exit 1
fi

# --- 3. Construct Prompt ---
PROMPT="Act as a professional editor to refine, polish, and improve the following text. 
Maintain the original language and tone, correcting grammar and enhancing the flow. 
If the content is toxic or aggressive, rephrase it to be professional and constructive 
while preserving the core message. Return ONLY the refined text.

Text to polish:
$TEXT"

# --- 4. Send Request ---
notify "$TITLE" "Polishing text via $PROVIDER..."

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

        # Extract only the part that is NOT a thought (Gemma 4 specific)
        REFINED_TEXT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[] | select(.thought != true) | .text')

        if [ -n "$REFINED_TEXT" ] && [ "$REFINED_TEXT" != "null" ]; then
            MODEL_USED="$M"
            TITLE="Cloud (${MODEL_USED})"
            break
        fi
        LAST_ERROR="Model $M returned empty refined text"
        echo "$LAST_ERROR, trying next..." >&2
    done

    # AUTOMATIC FALLBACK TO OLLAMA IF CLOUD FAILED
    if [ -z "$REFINED_TEXT" ] || [ "$REFINED_TEXT" == "null" ]; then
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
    # Local Ollama Request
    JSON_DATA=$(jq -n --arg t "$PROMPT" --arg m "$MODEL" '{model: $m, prompt: $t, stream: false}')
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
            REFINED_TEXT=$(echo "$RESPONSE" | jq -r '.response')
            if [ -n "$REFINED_TEXT" ] && [ "$REFINED_TEXT" != "null" ]; then
                MODEL_USED="$MODEL"
                TITLE="Local (${MODEL_USED})"
            else
                LAST_ERROR="Local model returned empty refined text"
            fi
        fi
    fi
fi

# --- 5. Result to buffer and notification ---
if [ -z "$REFINED_TEXT" ] || [ "$REFINED_TEXT" == "null" ]; then
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

# Normalize whitespace:
# - remove empty lines (including leading/trailing)
# - keep content lines as-is without inserting extra blank separators
REFINED_TEXT=$(
    printf '%s' "$REFINED_TEXT" | awk '
        {
            if ($0 ~ /^[[:space:]]*$/) {
                next
            }
            print
        }
    '
)

# Put to clipboard
if [ "$CLIPBOARD_BACKEND" == "wayland" ]; then
    if ! echo -n "$REFINED_TEXT" | wl-copy; then
        fatal "Failed to copy refined text via wl-copy"
    fi
else
    if ! echo -n "$REFINED_TEXT" | xclip -selection clipboard; then
        fatal "Failed to copy refined text via xclip"
    fi
fi

# FINAL NOTIFICATION (show refined text)
notify "Done! (${MODEL_USED})" "$REFINED_TEXT"
