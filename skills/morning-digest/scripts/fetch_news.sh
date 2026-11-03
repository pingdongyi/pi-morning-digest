#!/data/data/com.termux/files/usr/bin/bash
# Fetch today's international news headlines from Google News RSS.
# Usage: fetch_news.sh [--world] [--count N] [--attempts N] [--retry-delay S]

set -euo pipefail

COUNT=25
FEED="https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en"
ATTEMPTS=3
RETRY_DELAY=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --world)
      FEED="https://news.google.com/rss/headlines/section/topic/WORLD?hl=en-US&gl=US&ceid=US:en"
      shift
      ;;
    --count)
      COUNT="$2"
      shift 2
      ;;
    --attempts)
      ATTEMPTS="$2"
      shift 2
      ;;
    --retry-delay)
      RETRY_DELAY="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: fetch_news.sh [--world] [--count N] [--attempts N] [--retry-delay S]" >&2
      exit 2
      ;;
  esac
done

TMPFILE="$(mktemp)"
trap 'rm -f "$TMPFILE"' EXIT

# --- Fetch with retries: a single transient network blip must not kill the digest ---
ok=0
for ((i = 1; i <= ATTEMPTS; i++)); do
  if curl -sL --retry 2 --retry-delay 3 --max-time 20 "$FEED" -o "$TMPFILE" \
     && [[ -s "$TMPFILE" ]] \
     && grep -q '<title>' "$TMPFILE"; then
    ok=1
    break
  fi
  rm -f "$TMPFILE"
  if [[ $i -lt $ATTEMPTS ]]; then
    sleep "$RETRY_DELAY"
  fi
done

if [[ $ok -eq 0 ]]; then
  echo "ERROR: failed to fetch news feed (network issue?)" >&2
  exit 1
fi

# --- Extract <title> tags, decode entities, skip the first two ---
# (feed title and the "Google News" label). Capture ALL titles into a variable
# first, then print only the first COUNT. Using `head` inside a pipefail
# pipeline can kill upstream commands with SIGPIPE on larger feeds, causing
# intermittent false failures, so we avoid it entirely.
TITLES="$(
  grep -oP '(?<=<title>).*?(?=</title>)' "$TMPFILE" \
  | sed 's/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g; s/&lt;/</g; s/&gt;/>/g' \
  | tail -n +3 \
  || true
)"

if [[ -z "$TITLES" ]]; then
  echo "ERROR: news feed contains no headlines" >&2
  exit 1
fi

idx=0
while IFS= read -r line; do
  if [[ -z "$line" ]]; then
    continue
  fi
  idx=$((idx + 1))
  if [[ $idx -gt $COUNT ]]; then
    break
  fi
  printf '%2d. %s\n' "$idx" "$line"
done <<< "$TITLES"
