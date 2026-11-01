#!/data/data/com.termux/files/usr/bin/bash
# Install the boot auto-start hook for the morning digest.
#
# Places a script in ~/.termux/boot/ (Termux:Boot) that, on boot, re-establishes
# the morning digest chain if it is not already running. It checks the scheduler's
# PID file (kill -0) instead of matching process names, so it is robust.
#
# Usage: setup-boot.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOT_DIR="$HOME/.termux/boot"
mkdir -p "$BOOT_DIR"

cat > "$BOOT_DIR/morning-digest.sh" <<BOOT
#!/data/data/com.termux/files/usr/bin/bash
# Auto-start the morning digest chain on boot (installed by pi-morning-digest).
set -euo pipefail
SCHEDULER="$SCRIPT_DIR/morning-digest-scheduler.sh"
PID_FILE="\${MORNING_DIGEST_PIDFILE:-\$HOME/.local/state/pi-morning-digest-scheduler.pid}"
if [ -f "\$PID_FILE" ]; then
  OLD_PID="\$(cat "\$PID_FILE" 2>/dev/null || true)"
  if [ -n "\$OLD_PID" ] && kill -0 "\$OLD_PID" 2>/dev/null; then
    exit 0 # chain is already alive
  fi
fi
termux-job-scheduler --job-id 1 --period-ms 0 --persisted true \
  --network none --battery-not-low false --script "\$SCHEDULER" >/dev/null 2>&1 || true
BOOT

chmod +x "$BOOT_DIR/morning-digest.sh"
echo "installed boot hook: $BOOT_DIR/morning-digest.sh"
echo "requires the Termux:Boot app to run it on boot."
