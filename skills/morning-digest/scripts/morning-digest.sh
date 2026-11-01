#!/usr/bin/env bash
# Morning digest: fetch today's international news + device info and send it as
# a Termux notification. Designed to run headlessly (e.g. via termux-job-scheduler).
#
# Usage: morning-digest.sh [options]
#   --count N      number of headlines (default 8)
#   --title TEXT   notification title (default "🌅 晨间简报")
#   --no-battery   skip battery/device info
#   --no-news      skip news headlines (device info only)
#   --no-ip        skip IP country
#   --dry-run      print the digest instead of sending a notification

set -euo pipefail

COUNT=8
TITLE="🌅 晨间简报"
BATTERY=1
NEWS=1
IPINFO=1
DRYRUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --count) COUNT="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --no-battery) BATTERY=0; shift ;;
    --no-news) NEWS=0; shift ;;
    --no-ip) IPINFO=0; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH="$SCRIPT_DIR/fetch_news.sh"

DATE="$(date '+%Y-%m-%d %H:%M')"
LINES=()

# --- News ---
if [[ $NEWS -eq 1 ]]; then
  NEWS_TEXT="$(bash "$FETCH" --count "$COUNT" 2>/dev/null || echo "（新闻获取失败）")"
  LINES+=("📰 今日国际新闻")
  while IFS= read -r line; do
    [[ -n "$line" ]] && LINES+=("$line")
  done <<< "$NEWS_TEXT"
  LINES+=("")
fi

# --- Device info ---
if [[ $BATTERY -eq 1 ]]; then
  if command -v termux-battery-status >/dev/null 2>&1; then
    BATT="$(termux-battery-status 2>/dev/null | sed -n 's/.*"percentage": *\([0-9]*\).*/\1/p' | head -1)"
    [[ -n "$BATT" ]] && LINES+=("🔋 电量 ${BATT}%")
  fi
fi

if [[ $IPINFO -eq 1 ]]; then
  # Reuse the ip-country package's trace endpoint for the caller's own country.
  TRACE="$(curl -s --max-time 8 https://chatgpt.com/cdn-cgi/trace 2>/dev/null || true)"
  LOC="$(printf '%s\n' "$TRACE" | sed -n 's/^loc=//p' | head -1)"
  [[ -n "$LOC" ]] && LINES+=("📍 $LOC")
fi

CONTENT="$(printf '%s\n' "$DATE")"
[[ ${#LINES[@]} -gt 0 ]] && CONTENT="$CONTENT

$(printf '%s\n' "${LINES[@]}")"

if [[ $DRYRUN -eq 1 ]]; then
  printf '%s\n' "TITLE: $TITLE"
  printf '%s\n' "$CONTENT"
  exit 0
fi

if command -v termux-notification >/dev/null 2>&1; then
  printf '%s\n' "$CONTENT" | termux-notification -t "$TITLE" --priority high --id morning-digest
  echo "sent notification: $TITLE"
else
  echo "termux-notification not found; digest:" >&2
  printf '%s\n' "$CONTENT" >&2
  exit 1
fi
