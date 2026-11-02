#!/data/data/com.termux/files/usr/bin/bash
# Morning digest: fetch today's international news and send it as a Termux
# notification. A pure news briefing. Designed to run headlessly
# (e.g. via termux-job-scheduler).
#
# Usage: morning-digest.sh [options]
#   --count N      number of headlines (default 8)
#   --title TEXT   notification title (default "🌅 晨间简报")
#   --no-news      skip news headlines
#   --dry-run      print the digest instead of sending a notification

set -euo pipefail

COUNT=8
TITLE="🌅 晨间简报"
NEWS=1
DRYRUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --count) COUNT="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --no-news) NEWS=0; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FETCH="$SCRIPT_DIR/fetch_news.sh"

DATE="$(date '+%Y-%m-%d %H:%M')"
LINES=()

# --- News ---
FETCH_FAILED=0
if [[ $NEWS -eq 1 ]]; then
  if NEWS_TEXT="$(bash "$FETCH" --count "$COUNT" 2>/dev/null)"; then
    FETCH_FAILED=0
  else
    NEWS_TEXT="（新闻获取失败）"
    FETCH_FAILED=1
  fi
  LINES+=("📰 今日国际新闻")
  while IFS= read -r line; do
    [[ -n "$line" ]] && LINES+=("$line")
  done <<< "$NEWS_TEXT"
  LINES+=("")
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
  if printf '%s\n' "$CONTENT" | termux-notification -t "$TITLE" --priority high --id morning-digest; then
    if [ "$FETCH_FAILED" -eq 1 ]; then
      echo "sent notification: $TITLE (news fetch failed)"
      exit 2
    else
      echo "sent notification: $TITLE"
      exit 0
    fi
  else
    echo "ERROR: termux-notification failed" >&2
    exit 1
  fi
else
  echo "termux-notification not found; digest:" >&2
  printf '%s\n' "$CONTENT" >&2
  exit 1
fi
