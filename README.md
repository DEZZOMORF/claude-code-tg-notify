# claude-code-tg-notify

Telegram notification after every Claude Code response. Works across all sessions via a `Stop` hook. Distributed as a Claude Code plugin — install with two commands, configure with one.

```
🔔 Claude finished · my-project · 14:23
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
   ```
5. **Restrict permissions**: `chmod 600 ~/.claude/tg-notify.env`

Next Claude response → Telegram ping.

## How it works

Ships a single `Stop` hook (runs after every assistant turn) that reads `~/.claude/tg-notify.env` and `curl`s the Telegram Bot API directly. No server, no proxy — your bot, your token, your data.

If the env file is missing or incomplete, the hook exits silently. Safe to install and configure later.

## Message format

```
🔔 Claude finished · <cwd-basename> · HH:MM
```

The project name is the basename of the current working directory. Time is local.

## Config file format

```
TELEGRAM_BOT_TOKEN=<token>
TELEGRAM_CHAT_ID=<numeric chat id>
```

No quotes, no spaces around `=`. The file is sourced by Bash, so shell metacharacters in values would be interpreted.

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

**Too noisy.** The hook fires after every assistant response. If you want to gate by duration or only for specific projects, fork and customize `hooks/notify.sh` — it's 20 lines of shell.

## Uninstall

```
/plugin uninstall tg-notify@dezzomorf
rm ~/.claude/tg-notify.env
```

## License

MIT
