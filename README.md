# pi-morning-digest

A [Pi](https://pi.dev) package for a **morning digest (晨间简报)**:

- **Skill** `morning-digest` — asks the model to compose today's digest
  (international news + device context) and present it, or push it as a notification.
- **Script** `scripts/morning-digest.sh` — a headless digest that fetches fresh
  headlines and sends a `termux-notification`. Great for scheduled delivery.

## Install

```bash
pi install git:https://github.com/pingdongyi/pi-morning-digest.git@v1
```

## Use in pi

Ask the model: "帮我做晨间简报" or "push 晨间简报给我". It will use the
`morning-digest` skill to fetch news and (on request) push it.

## Headless / scheduled push

Preview the digest:

```bash
scripts/morning-digest.sh --dry-run --count 10
```

Send it as a notification:

```bash
scripts/morning-digest.sh --count 10
```

### Schedule it daily at a fixed time (Termux API)

`termux-job-scheduler` only supports intervals, not "run at HH:MM". To align the
digest to a fixed time (e.g. **09:30**), use the self-rescheduling one-shot chain:

```bash
# Start once — it fires immediately, waits until the next 09:30, sends the digest,
# then re-schedules itself for the following day.
termux-job-scheduler --job-id 1 --period-ms 0 --persisted true \
  --script "$HOME/.pi/agent/git/github.com/pingdongyi/pi-morning-digest/skills/morning-digest/scripts/morning-digest-scheduler.sh"
```

The scheduler (`morning-digest-scheduler.sh`) sleeps until the next `HH:MM`
(default 09:30), sends the digest, then re-schedules the next one-shot. So **each
execution re-schedules the next** — that is the trade-off for exact time-of-day
with the Termux job scheduler.

Options: `--hour H --minute M --count N --job-id ID` (job-id must be an **integer**).

Manage it:

```bash
termux-job-scheduler --pending                  # list jobs
termux-job-scheduler --cancel --job-id 1        # stop the chain
```

> Caveat: the chain sleeps for up to ~24h between runs. If the device kills the
> background process, the chain stops; re-run the start command to resume. For a
> more robust daily delivery, use cron (below) instead.

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `--count N` | `8` | Number of headlines |
| `--title TEXT` | `🌅 晨间简报` | Notification title |
| `--no-battery` | off | Skip battery info |
| `--no-news` | off | Skip news headlines |
| `--no-ip` | off | Skip IP country |
| `--dry-run` | off | Print instead of sending |

## Notes

- Requires `curl`; notification push requires `termux-notification` (Termux:API).
- News fetching mirrors the `pi-international-news` package (Google News RSS).
