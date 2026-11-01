#!/usr/bin/env bash
# termux-job-scheduler entry point for a daily morning digest at a fixed time.
#
# This is a SELF-RESCHEDULING ONE-SHOT chain: termux-job-scheduler has no
# "run at HH:MM" option, so each run sleeps until the next HH:MM, sends the
# digest, then re-schedules this script (one-shot) for the following day.
#
# Usage:
#   morning-digest-scheduler.sh [--hour H] [--minute M] [--count N] [--job-id ID] [--dry-run]
#
# To start, schedule it once (fires immediately, then chains daily):
#   termux-job-scheduler --job-id morning-digest --period-ms 0 \
#     --script "$HOME/.../scripts/morning-digest-scheduler.sh" --persisted

set -euo pipefail

HOUR=9
MINUTE=30
COUNT=10
JOB_ID=morning-digest
DRYRUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hour) HOUR="$2"; shift 2 ;;
    --minute) MINUTE="$2"; shift 2 ;;
    --count) COUNT="$2"; shift 2 ;;
    --job-id) JOB_ID="$2"; shift 2 ;;
    --dry-run) DRYRUN=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIGEST="$SCRIPT_DIR/morning-digest.sh"

NOW=$(date +%s)
TODAY=$(date +%Y-%m-%d)
HHMM=$(printf '%02d:%02d' "$HOUR" "$MINUTE")

# Next occurrence of HH:MM (today if still ahead, otherwise tomorrow).
TARGET=$(date -d "$TODAY $HHMM" +%s 2>/dev/null || echo "$NOW")
if (( TARGET <= NOW )); then
  TARGET=$(date -d "tomorrow $HHMM" +%s 2>/dev/null || echo "$NOW")
fi
SLEEP_SECS=$((TARGET - NOW))

echo "[morning-digest] next digest at ${HHMM} daily; sleeping ${SLEEP_SECS}s" >&2
sleep "$SLEEP_SECS"

if [[ $DRYRUN -eq 1 ]]; then
  echo "[morning-digest] (dry-run) would send digest + re-schedule job '$JOB_ID'" >&2
  bash "$DIGEST" --dry-run --count "$COUNT"
else
  bash "$DIGEST" --count "$COUNT" || true
fi

# Re-schedule the next one-shot for the following day.
if [[ $DRYRUN -eq 0 ]] && command -v termux-job-scheduler >/dev/null 2>&1; then
  termux-job-scheduler --job-id "$JOB_ID" --period-ms 0 --script "$0" --persisted >/dev/null 2>&1 || true
  echo "[morning-digest] re-scheduled next run (job '$JOB_ID')" >&2
fi
