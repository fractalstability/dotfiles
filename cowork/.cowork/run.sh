#!/bin/bash
# Cowork SSH wrapper — logs commands + output for visibility
CMD="$1"
LOGFILE="$HOME/.cowork/session.log"

echo "" >> "$LOGFILE"
echo "── $(date '+%Y-%m-%d %H:%M:%S') ──────────────────────────" >> "$LOGFILE"
echo "CMD: $CMD" >> "$LOGFILE"
echo "────────────────────────────────────────────────────────" >> "$LOGFILE"

output=$(eval "$CMD" 2>&1)
exit_code=$?

echo "$output" >> "$LOGFILE"
echo "EXIT: $exit_code" >> "$LOGFILE"

echo "$output"
exit $exit_code
