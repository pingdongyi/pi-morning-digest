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

### Schedule it daily (Termux)

Using the Termux job scheduler (runs daily from the moment you schedule it):

```bash
termux-job-scheduler --job-id morning-digest --period-ms 86400000 \
  --script "$HOME/.pi/agent/git/github.com/pingdongyi/pi-morning-digest/skills/morning-digest/scripts/morning-digest.sh"
```

Or with cron, to run at a specific time (e.g. 07:30) instead of every 24h:

```bash
30 7 * * * /path/to/scripts/morning-digest.sh --count 10
```

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
