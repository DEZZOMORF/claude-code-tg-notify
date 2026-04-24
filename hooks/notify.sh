#!/usr/bin/env bash
# tg-notify: Claude Code Stop hook -> Telegram
# Config: ~/.claude/tg-notify.env with TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID

set -u

CONFIG="${HOME}/.claude/tg-notify.env"
[ -f "$CONFIG" ] || exit 0

# shellcheck disable=SC1090
. "$CONFIG"

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
  exit 0
fi

# Drain stdin (Claude Code pipes hook JSON in; we don't need it for the basic message)
cat >/dev/null 2>&1 || true

project="$(basename "$PWD")"
time_str="$(date +%H:%M)"
text="🔔 Claude finished · ${project} · ${time_str}"

curl -sS -m 5 \
  -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${text}" \
  >/dev/null 2>&1 || true

exit 0
