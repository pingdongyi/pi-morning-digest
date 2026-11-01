#!/data/data/com.termux/files/usr/bin/bash
# termux-job-scheduler PERIODIC job: single-check morning digest (非常驻).
#
# 每次触发: 若当前时间在目标窗口 (HH:MM ± WINDOW) 且今天尚未发送, 则发送晨报;
# 否则跳过并退出。由 termux-job-scheduler --period-ms 定期调用,
# 与 codex-supervisor 的实现一致 (周期 job + 单次检查, 无常驻进程)。
#
# Usage:
#   morning-digest-scheduler.sh [--hour H] [--minute M] [--count N] [--window M] [--dry-run]

set -uo pipefail

LOG="${MORNING_DIGEST_LOG:-$HOME/.local/state/pi-morning-digest.log}"
STATE_FILE="${MORNING_DIGEST_STATE:-$HOME/.local/state/pi-morning-digest.state}"
mkdir -p "$(dirname "$LOG")" "$(dirname "$STATE_FILE")"
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

HOUR=9
MINUTE=30
COUNT=10
WINDOW=15          # 目标窗口 ±15 分钟
DRYRUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hour) HOUR="$2"; shift 2 ;;
    --minute) MINUTE="$2"; shift 2 ;;
    --count) COUNT="$2"; shift 2 ;;
    --window) WINDOW="$2"; shift 2 ;;
    --dry-run) DRYRUN=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIGEST="$SCRIPT_DIR/morning-digest.sh"

TODAY=$(date +%Y-%m-%d)
NOW=$(date +%s)
LAST_SENT="$(cat "$STATE_FILE" 2>/dev/null || true)"

# 今天已发送 -> 跳过 (防重复)
if [ "$LAST_SENT" = "$TODAY" ]; then
  log "today already sent, skip (now=$(date '+%H:%M'))"
  echo "already-sent"
  exit 0
fi

HHMM=$(printf '%02d:%02d' "$HOUR" "$MINUTE")
TARGET=$(date -d "$TODAY $HHMM" +%s 2>/dev/null || echo "$NOW")
WIN_START=$((TARGET - WINDOW * 60))
WIN_END=$((TARGET + WINDOW * 60))

if [ "$NOW" -ge "$WIN_START" ] && [ "$NOW" -le "$WIN_END" ]; then
  if [ "$DRYRUN" -eq 1 ]; then
    bash "$DIGEST" --dry-run --count "$COUNT" || true
    echo "would-send (window $HHMM ±${WINDOW}m)"
  else
    bash "$DIGEST" --count "$COUNT" || true
    printf '%s' "$TODAY" > "$STATE_FILE"
    log "sent digest at $(date '+%H:%M')"
    echo "sent"
  fi
else
  log "not in window (now=$(date '+%H:%M') target=$HHMM ±${WINDOW}m)"
  echo "not-in-window"
fi
