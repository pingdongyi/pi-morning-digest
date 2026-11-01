---
name: morning-digest
description: Compose and send a morning digest (今日晨间简报). Use when the user asks for a morning briefing/digest, 晨间简报, 早报, 每日摘要, or to receive today's news summary as a notification.
compatibility: Requires curl, and termux-notification for the push option.
---

# Morning Digest (晨间简报)

Compose a friendly morning digest for today: international news headlines plus a
little device context, then present it (and optionally push it as a device
notification).

## When to use

Use this skill when the user asks for:
- a morning digest / briefing / 晨间简报 / 早报 / 每日摘要
- today's news in the morning
- a daily summary delivered as a notification

## How it works

A script fetches fresh headlines (Google News RSS) and a script can push the
digest as a `termux-notification`. You organize the digest and, if the user wants
a push, trigger the notification.

## Steps

### 1. Confirm the date

Use the current date (e.g. `date '+%Y-%m-%d %A'`) for the digest header.

### 2. Fetch the headlines

Run the fetch script:
`scripts/fetch_news.sh --count 20`

It prints a numbered list `N. <Headline> - <Source>`. If it fails or returns an
error, mention the news feed is unavailable and continue with the rest of the digest.

### 3. Gather device context (optional)

- Battery: `termux-battery-status` (percent).
- Your IP country: use the `ip_country` tool (from the ip-country package) or the
  Cloudflare trace endpoint.

### 4. Compose the digest

Present a friendly Chinese digest, e.g.:

```
🌅 晨间简报 · 2026-11-01 星期六

📰 今日国际新闻
1. <headline> - <source>
2. <headline> - <source>
...

🔋 电量 85% · 📍 SG
```

Greet with a time-appropriate opener (早上好/早安). Keep it concise.

### 5. Deliver

- By default present the digest in chat.
- If the user asks to **push / 推送 / 通知**: send it with `termux-notification`:
  `echo "<digest>" | termux-notification -t "🌅 晨间简报" --priority high --id morning-digest`
- For a fully headless scheduled digest, run `scripts/morning-digest.sh --dry-run`
  to preview, or the same script without `--dry-run` to send the notification
  directly (used by `termux-job-scheduler` / cron).

## Notes

- Always fetch fresh headlines; do not reuse stale ones.
- The headless script is the same digest used for scheduled push. Offer to set up
  a schedule if the user wants an automatic morning delivery.
- If `termux-notification` is unavailable, tell the user and show the digest in chat.
