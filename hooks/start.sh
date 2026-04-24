#!/usr/bin/env bash
# tg-notify: record response start time on UserPromptSubmit.
# Stop hook reads this to compute duration and decide whether to notify.

set -u

input=$(cat 2>/dev/null || true)
session_id=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)

# session_id must be safe for a file path
case "$session_id" in
  ''|*[!A-Za-z0-9_-]*) exit 0 ;;
esac

date +%s > "/tmp/tg-notify-${session_id}.start" 2>/dev/null || true
exit 0
