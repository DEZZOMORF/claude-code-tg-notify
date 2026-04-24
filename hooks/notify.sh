#!/usr/bin/env bash
# tg-notify: Claude Code Stop hook -> Telegram
# Config: ~/.claude/tg-notify.env with TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID,
#         and optional TELEGRAM_MIN_DURATION_SECONDS (skip if response faster than this)

set -u

CONFIG="${HOME}/.claude/tg-notify.env"
[ -f "$CONFIG" ] || exit 0

# shellcheck disable=SC1090
. "$CONFIG"

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
  exit 0
fi

min_duration="${TELEGRAM_MIN_DURATION_SECONDS:-0}"

input=$(cat 2>/dev/null || true)
session_id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)

duration=""
case "$session_id" in
  ''|*[!A-Za-z0-9_-]*) : ;;
  *)
    start_file="/tmp/tg-notify-${session_id}.start"
    if [ -f "$start_file" ]; then
      start_time=$(cat "$start_file" 2>/dev/null || echo "")
      rm -f "$start_file"
      if [ -n "$start_time" ]; then
        now=$(date +%s)
        duration=$((now - start_time))
        if [ "$duration" -lt "$min_duration" ]; then
          exit 0
        fi
      fi
    fi
    ;;
esac

format_duration() {
  s=$1
  if [ "$s" -lt 60 ]; then
    printf '%ds' "$s"
  elif [ "$s" -lt 3600 ]; then
    printf '%dm %ds' $((s/60)) $((s%60))
  else
    printf '%dh %dm' $((s/3600)) $(((s%3600)/60))
  fi
}

project="$(basename "$PWD")"
if [ -n "$duration" ]; then
  dur_str=$(format_duration "$duration")
  text="🔔 Claude finished · ${project} · ${dur_str}"
else
  text="🔔 Claude finished · ${project}"
fi

curl -sS -m 5 \
  -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${text}" \
  >/dev/null 2>&1 || true

exit 0
