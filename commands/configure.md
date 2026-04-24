---
description: Set up Telegram notifications for Claude Code (bot token + chat id)
---

Walk the user through configuring `tg-notify`. Follow these steps in order:

1. **Check whether config already exists** at `~/.claude/tg-notify.env`.
   - If it does, ask whether they want to reconfigure or just send a test message. If test only, skip to step 5.

2. **Create a Telegram bot** (if they don't have one):
   - Tell them to open [@BotFather](https://t.me/BotFather) in Telegram.
   - Send `/newbot`, pick a display name, pick a username ending in `bot`.
   - Copy the bot token (looks like `123456789:ABCdef...`).
   - Ask them to paste the token.
   - **Do not echo the token back** in your response. Treat as secret.

3. **Get chat_id** via [@userinfobot](https://t.me/userinfobot):
   - Tell them to open the link and press `Start`.
   - Copy the numeric `Id` field.
   - Ask them to paste the chat_id.

4. **Important — activate the bot for themselves**: tell them to open their new bot (username from step 2) and send any message (e.g., `/start`). Telegram won't let a bot message a user who has never initiated a chat with it.

5. **Write the config file** using this exact format (no quotes, no spaces around `=`):

   ```
   TELEGRAM_BOT_TOKEN=<token>
   TELEGRAM_CHAT_ID=<chat_id>
   TELEGRAM_MIN_DURATION_SECONDS=0
   ```

   `TELEGRAM_MIN_DURATION_SECONDS` is optional — if set, responses faster than this many seconds won't trigger a notification (default `0` = always notify). Ask the user if they want a threshold (e.g. `60` to silence quick replies).

   Create `~/.claude/tg-notify.env` with those lines, then run `chmod 600 ~/.claude/tg-notify.env` to restrict permissions.

6. **Send a test message** by sourcing the config and `curl`ing Telegram directly:

   ```bash
   set -a; source ~/.claude/tg-notify.env; set +a
   curl -sS -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
     --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
     --data-urlencode "text=✅ tg-notify connected"
   ```

   Check the JSON response has `"ok":true`. If not, report the `description` field from the response to the user — common causes: bot never messaged (step 4 skipped), wrong chat_id, revoked token.

7. **Confirm with the user** that the message arrived in Telegram. Done.
