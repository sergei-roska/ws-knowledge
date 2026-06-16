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
    notify "Promptify Error" "$msg"
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

extract_text_from_google_response() {
    local response="$1"
    echo "$response" | jq -r '.candidates[0].content.parts[] | select(.thought != true) | .text'
}

call_with_current_provider() {
    local instruction="$1"
    local json_data
    local http_response
    local http_code
    local response
    local result
    local curl_exit
    local m

    if [ "$PROVIDER" == "google" ]; then
        json_data=$(jq -n --arg t "$instruction" '{contents: [{parts: [{text: $t}]}]}')
        for m in "${GOOGLE_MODELS[@]}"; do
            TITLE="Cloud (${m})"
            http_response=$(curl --silent --show-error --max-time 45 --connect-timeout 10 -w $'\n%{http_code}' \
                -X POST "https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent" \
                -H 'Content-Type: application/json' \
                -H "x-goog-api-key: ${API_KEY}" \
                -d "$json_data")
            curl_exit=$?
            if [ "$curl_exit" -ne 0 ]; then
                LAST_ERROR="Model $m request failed (curl exit $curl_exit)"
                continue
            fi
            http_code="${http_response##*$'\n'}"
            response="${http_response%$'\n'*}"
            RESPONSE="$response"
            if ! [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
                LAST_ERROR="Model $m returned HTTP $http_code"
                continue
            fi
            if ! echo "$response" | jq -e . >/dev/null 2>&1; then
                LAST_ERROR="Model $m returned invalid JSON"
                continue
            fi
            result=$(extract_text_from_google_response "$response")
            result=$(printf '%s' "$result" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            [ -n "$result" ] || { LAST_ERROR="Model $m returned empty response"; continue; }
            MODEL_USED="$m"
            printf '%s' "$result"
            return 0
        done

        PROVIDER="ollama"
        MODEL="$LOCAL_FALLBACK_MODEL"
        TITLE="Local (${MODEL})"
        notify "$TITLE" "Cloud failed. Switching to local fallback model ${MODEL}."
    fi

    if [ "$PROVIDER" == "ollama" ]; then
        if ! can_reach_ollama_api; then
            LAST_ERROR="Local Ollama API is unreachable"
            return 1
        fi
        json_data=$(jq -n --arg p "$instruction" --arg m "$MODEL" '{model: $m, prompt: $p, stream: false}')
        http_response=$(curl --silent --show-error --max-time 45 --connect-timeout 10 -w $'\n%{http_code}' \
            -X POST "http://localhost:11434/api/generate" \
            -H 'Content-Type: application/json' \
            -d "$json_data")
        curl_exit=$?
        if [ "$curl_exit" -ne 0 ]; then
            LAST_ERROR="Local Ollama request failed (curl exit $curl_exit)"
            return 1
        fi
        http_code="${http_response##*$'\n'}"
        response="${http_response%$'\n'*}"
        RESPONSE="$response"
        if ! [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
            LAST_ERROR="Local Ollama returned HTTP $http_code"
            return 1
        fi
        if ! echo "$response" | jq -e . >/dev/null 2>&1; then
            LAST_ERROR="Local Ollama returned invalid JSON"
            return 1
        fi
        result=$(echo "$response" | jq -r '.response')
        result=$(printf '%s' "$result" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -n "$result" ] || { LAST_ERROR="Local model returned empty response"; return 1; }
        MODEL_USED="$MODEL"
        printf '%s' "$result"
        return 0
    fi

    LAST_ERROR="Unsupported provider state: $PROVIDER"
    return 1
}

# === SETTINGS ===
# PROVIDER: "google" or "ollama"
PROVIDER="${PROVIDER:-google}"
MODEL_USED="n/a"
LAST_ERROR=""
RESPONSE=""
TITLE="Promptify"

require_cmd curl
require_cmd jq

case "$PROVIDER" in
    google)
        GOOGLE_MODELS=("gemini-3.5-flash" "gemma-4-31b-it" "gemma-4-26b-a4b-it")
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

if [ "$PROVIDER" == "google" ] && ! can_reach_google_api; then
    LAST_ERROR="Google API is unreachable (network offline or blocked)"
    PROVIDER="ollama"
    MODEL="$LOCAL_FALLBACK_MODEL"
    TITLE="Local (${MODEL})"
    notify "$TITLE" "Google API is unreachable. Switching directly to local fallback model ${MODEL}."
fi

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

if [ -n "$WAYLAND_DISPLAY" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    if command -v wl-paste >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1; then
        CLIPBOARD_BACKEND="wayland"
    elif command -v xclip >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
        CLIPBOARD_BACKEND="x11"
    else
        fatal "No clipboard backend found for Wayland session"
    fi
elif [ -n "$DISPLAY" ]; then
    if command -v xclip >/dev/null 2>&1; then
        CLIPBOARD_BACKEND="x11"
    elif command -v wl-paste >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1; then
        CLIPBOARD_BACKEND="wayland"
    else
        fatal "No clipboard backend found for X11 session"
    fi
else
    fatal "Unable to detect graphical session (missing WAYLAND_DISPLAY/XDG_SESSION_TYPE/DISPLAY)"
fi

if [ "$CLIPBOARD_BACKEND" == "wayland" ]; then
    TEXT=$(wl-paste 2>/dev/null)
else
    TEXT=$(xclip -o -selection clipboard 2>/dev/null)
fi

[ -n "$TEXT" ] || fatal "Clipboard is empty"

PROMPT=$(cat <<'EOF'
You are a prompt optimizer for AI coding agents.
Transform the raw user prompt into a clear, structured, high-signal instruction that preserves intent.

Rules:
- Always keep the final prompt in the same primary language as the raw input.
- Never translate the user's prompt to another language.
- If input is mixed-language, keep the dominant language and preserve technical terms.
- Do not add new requirements that user did not ask for.
- Clarify expected output format and success criteria.
- Make constraints explicit (tech stack, files, behavior, edge-cases) only if they are implied by the input.
- Reduce ambiguity and fluff.
- Keep it practical and execution-ready.

Output format (strict):
line 1: FINAL_PROMPT:
line 2+: <optimized prompt text>

No markdown. No code fences. No commentary outside FINAL_PROMPT block.
EOF
)

notify "$TITLE" "Improving prompt from clipboard..."

PROMPT_TEXT="${PROMPT}"$'\n\n'"Raw prompt:"$'\n'"${TEXT}"
RESULT=$(call_with_current_provider "$PROMPT_TEXT")
[ -n "$RESULT" ] || fatal "All providers/models failed. Last error: ${LAST_ERROR:-unknown}"

if [ "$CLIPBOARD_BACKEND" == "wayland" ]; then
    echo -n "$RESULT" | wl-copy || fatal "Failed to copy result via wl-copy"
else
    echo -n "$RESULT" | xclip -selection clipboard || fatal "Failed to copy result via xclip"
fi

notify "Done! (${MODEL_USED})" "$RESULT"
