#!/usr/bin/env bash

set -u

CONFIG="${HOME}/.claude/tg-notify.env"
[ -f "$CONFIG" ] || exit 0

. "$CONFIG"

[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ] || exit 0
if [ -n "${TG_NOTIFY_REQUIRE_ENV:-}" ]; then
  printenv "$TG_NOTIFY_REQUIRE_ENV" >/dev/null 2>&1 || exit 0
fi
command -v jq >/dev/null 2>&1 || exit 0

mode="${1:-}"
input=$(cat 2>/dev/null || true)
[ -n "$input" ] || exit 0

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
project=$(basename "${cwd:-$PWD}")

case "$mode" in
  notification)
    message=$(printf '%s' "$input" | jq -r '.message // empty' 2>/dev/null)
    [ -n "$message" ] || exit 0
    text="🔐 ${project}
${message}"
    ;;
  ask)
    body=$(printf '%s' "$input" | jq -r '
      [.tool_input.questions[]?
        | "❓ " + .question + "\n"
          + ([.options[]? | "  • " + .label + (if (.description // "") != "" then " — " + .description else "" end)] | join("\n"))
      ] | join("\n\n")' 2>/dev/null)
    [ -n "$body" ] || exit 0
    text="💬 ${project}
${body}"
    ;;
  stop)
    last=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null)
    [ -n "$last" ] || exit 0
    paragraph=$(printf '%s\n' "$last" | awk '
      NF { buf = (buf == "" ? $0 : buf "\n" $0); next }
      buf != "" { last = buf; buf = "" }
      END { print (buf != "" ? buf : last) }')
    trimmed=$(printf '%s' "$paragraph" | sed -e 's/[[:space:]*_`]*$//')
    case "$trimmed" in
      *\?) ;;
      *) exit 0 ;;
    esac
    text="💬 ${project}
${paragraph}"
    ;;
  *)
    exit 0
    ;;
esac

text=$(printf '%s' "$text" | jq -Rrs '.[0:3800]')

curl -sS -m 5 \
  -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${text}" \
  >/dev/null 2>&1 || true

exit 0
