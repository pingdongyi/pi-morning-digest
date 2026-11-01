#!/data/data/com.termux/files/usr/bin/bash
# Install the boot auto-start hook for the morning digest.
#
# Places a script in ~/.termux/boot/ (Termux:Boot) that, on boot, re-establishes
# the morning digest chain if it is not already running. Idempotent: if the
# scheduler process is alive, it does nothing.
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
if pgrep -f "morning-digest-scheduler" >/dev/null 2>&1; then
  exit 0 # already running
fi
termux-job-scheduler --job-id 1 --period-ms 0 --persisted true \
  --network none --battery-not-low false --script "\$SCHEDULER" >/dev/null 2>&1 || true
BOOT

chmod +x "$BOOT_DIR/morning-digest.sh"
echo "installed boot hook: $BOOT_DIR/morning-digest.sh"
echo "requires the Termux:Boot app to run it on boot."
