#!/data/data/com.termux/files/usr/bin/bash
# 将 morning digest 注册为 termux-job-scheduler PERIODIC job (非常驻),
# 并安装应用启动恢复 hook。与 codex-supervisor 实现一致:
# 每次 job 触发运行 morning-digest-scheduler.sh (单次检查), 到窗口则发送, 否则跳过退出。
#
# Usage: setup-boot.sh [--period-ms N]   (默认 900000 = 15min 最小周期)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEDULER="$SCRIPT_DIR/morning-digest-scheduler.sh"
BOOT_DIR="$HOME/.termux/boot"
JOB_ID=1
PERIOD_MS="${1:-900000}"
MIN_MS=900000
[ "$PERIOD_MS" -lt "$MIN_MS" ] && PERIOD_MS=$MIN_MS

# 注册周期 job (幂等覆盖同 job-id)
termux-job-scheduler --job-id "$JOB_ID" --cancel >/dev/null 2>&1 || true
termux-job-scheduler --job-id "$JOB_ID" --period-ms "$PERIOD_MS" --persisted true \
  --network any --battery-not-low false --script "$SCHEDULER" >/dev/null 2>&1 \
  && echo "[ok] 已注册周期任务 job #$JOB_ID (每 $((PERIOD_MS/1000))s 单次检查)" \
  || echo "[warn] termux-job-scheduler 注册失败"

# boot hook: 幂等重新注册 job (无常驻进程)
mkdir -p "$BOOT_DIR"
cat > "$BOOT_DIR/morning-digest.sh" <<BOOT
#!/data/data/com.termux/files/usr/bin/bash
# Re-register morning digest periodic job (installed by pi-morning-digest).
set -uo pipefail
termux-job-scheduler --job-id $JOB_ID --period-ms $PERIOD_MS --persisted true \
  --network any --battery-not-low false --script "$SCHEDULER" >/dev/null 2>&1 || true
BOOT
chmod +x "$BOOT_DIR/morning-digest.sh"
echo "[ok] 已安装应用启动恢复: $BOOT_DIR/morning-digest.sh"

echo
echo "=== 当前状态 ==="
termux-job-scheduler --pending 2>&1 | head -8
