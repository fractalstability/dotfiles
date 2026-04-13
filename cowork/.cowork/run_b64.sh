#!/bin/bash
# Cowork b64 runner — tmux display (colors) + file capture
# Usage: ~/.cowork/run_b64.sh 'BASE64STRING'
# Returns: pipe-delimited, ANSI-stripped output

TMUX=/usr/local/bin/tmux
B64="$1"
CMD=$(echo "$B64" | base64 -d)
SENTINEL="__COWORK_DONE_$$__"
OUTFILE="$HOME/.cowork/last_output.txt"
LOGFILE="$HOME/.cowork/session.log"
CMDFILE="$HOME/.cowork/next_cmd.sh"

# Log the command
printf '\n── %s [tmux] ────────────────────────────────\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOGFILE"
echo "CMD: $CMD" >> "$LOGFILE"
echo '─────────────────────────────────────────────────────────' >> "$LOGFILE"

# Write temp script: runs command, tees output, writes sentinel
printf '#!/bin/bash\n{ %s ; } 2>&1 | tee "%s"\necho "%s" >> "%s"\n' \
  "$CMD" "$OUTFILE" "$SENTINEL" "$OUTFILE" > "$CMDFILE"
chmod +x "$CMDFILE"

# Clear previous output
> "$OUTFILE"

# Send to tmux pane
$TMUX send-keys -t cowork "bash $CMDFILE" Enter

# Poll for sentinel (up to 120s)
for i in $(seq 1 120); do
    sleep 1
    grep -q "$SENTINEL" "$OUTFILE" 2>/dev/null && break
done

# Strip \r, ANSI codes, and sentinel; log clean output
clean=$(tr -d '\r' < "$OUTFILE" \
  | sed 's/\x1b\[[0-9;]*[mGKHFJABCDfnsuhl]//g' \
  | sed 's/\x1b[=>]//g' \
  | grep -v "$SENTINEL")
echo "$clean" >> "$LOGFILE"
echo '─────────────────────────────────────────────────────────' >> "$LOGFILE"

# Return pipe-delimited (AppleScript strips \n on return; | survives)
echo "$clean" | sed 's/$/|/' | tr -d '\n'
