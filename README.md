# claude-code-tg-notify

Telegram notification after every Claude Code response. Works across all sessions via a `Stop` hook. Distributed as a Claude Code plugin — install with two commands, configure with one.

```
🔔 Claude finished · my-project · 2m 15s
```

## Install

```
/plugin marketplace add DEZZOMORF/claude-code-tg-notify
/plugin install tg-notify@dezzomorf
```

Then configure:

```
/tg-notify:configure
```

Claude walks you through creating a bot, getting your chat ID, and writing the config. Or set it up manually — see below.

## Manual setup

1. **Create a bot** via [@BotFather](https://t.me/BotFather): send `/newbot`, follow prompts, copy the token.
2. **Get your chat ID** via [@userinfobot](https://t.me/userinfobot): send `/start`, copy the numeric `Id`.
3. **Send any message to your new bot** (e.g. `/start`). Telegram won't deliver bot messages to users who've never initiated a chat.
4. **Write `~/.claude/tg-notify.env`**:
   ```
   TELEGRAM_BOT_TOKEN=123456789:ABC...
   TELEGRAM_CHAT_ID=987654321
   TELEGRAM_MIN_DURATION_SECONDS=0
   ```
5. **Restrict permissions**: `chmod 600 ~/.claude/tg-notify.env`

Next Claude response → Telegram ping.

## How it works

Ships two hooks: `UserPromptSubmit` records the start time of each turn to `/tmp/tg-notify-<session>.start`, and `Stop` (after every assistant turn) reads it, computes duration, applies the optional threshold, then `curl`s the Telegram Bot API. No server, no proxy — your bot, your token, your data.

If the env file is missing or incomplete, the hook exits silently. Safe to install and configure later.

## Message format

```
🔔 Claude finished · <cwd-basename> · <duration>
```

Duration is formatted as `45s`, `2m 15s`, or `1h 23m`. If the start timestamp is missing (e.g. first turn after install), the duration is omitted.

## Config file format

```
TELEGRAM_BOT_TOKEN=<token>
TELEGRAM_CHAT_ID=<numeric chat id>
TELEGRAM_MIN_DURATION_SECONDS=<integer, optional>
```

No quotes, no spaces around `=`. The file is sourced by Bash, so shell metacharacters in values would be interpreted.

`TELEGRAM_MIN_DURATION_SECONDS` suppresses notifications for responses faster than the given number of seconds (default `0` = always notify). Set to e.g. `60` if you only care about long-running turns.

## Troubleshooting

**No message arrives.** Open `https://api.telegram.org/bot<TOKEN>/getMe` in a browser — should return your bot info. If not, the token is wrong or revoked. Then try sending a test manually:

```bash
set -a; source ~/.claude/tg-notify.env; set +a
curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=test"
```

The response JSON will tell you what's wrong (common: `"chat not found"` = wrong chat_id or you never messaged the bot first).

**Hook runs but nothing happens.** Check the config file is readable and has both vars set:
```bash
cat ~/.claude/tg-notify.env
```

**Too noisy.** Set `TELEGRAM_MIN_DURATION_SECONDS=60` (or any threshold) in the env file to skip quick responses. For project-specific filtering, fork and customize `hooks/notify.sh`.

## Uninstall

```
/plugin uninstall tg-notify@dezzomorf
rm ~/.claude/tg-notify.env
```

## License

MIT
