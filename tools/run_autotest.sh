#!/usr/bin/env bash
# Run an automated play-through and fail loudly on any script error.
# usage: tools/run_autotest.sh <scenario> <outdir> [timing] [extra args...]
#   scenario: full | incident | night | departure | title | controls | manual | gallery
#   timing:   perfect | good | miss | mixed   (default perfect)
set -u
cd "$(dirname "$0")/.."
G="${GODOT:-/c/Users/LAPTOP 5/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
SC="${1:-full}"
OUT="${2:-qa/shots/latest}"
TIM="${3:-perfect}"
shift 3 2>/dev/null || shift $#
rm -rf "$OUT"
LOG="$(mktemp)"
timeout 900 "$G" --path . --resolution 1280x720 -- --autotest="$SC" --shots="$OUT" --timing="$TIM" --fast "$@" >"$LOG" 2>&1 &
PID=$!
# a script that fails to load leaves the window idle forever: stop early instead of waiting for the timeout
while kill -0 $PID 2>/dev/null; do
  if grep -q -E "Parse Error|Failed to load script|Compile Error" "$LOG"; then
    sleep 1; taskkill //F //IM Godot_v4.7.2-stable_win64.exe >/dev/null 2>&1; kill $PID 2>/dev/null; break
  fi
  sleep 2
done
wait $PID
code=$?
grep -E "autotest\]|ERROR|WARNING: .*(leak|Leak)" "$LOG" | grep -v "shot " | head -60
errs=$(grep -c -E "SCRIPT ERROR|^ERROR" "$LOG")
echo "---- exit=$code script_errors=$errs shots=$(ls "$OUT" 2>/dev/null | grep -c png)"
if [ "$errs" -gt 0 ]; then
  grep -A3 -E "SCRIPT ERROR|^ERROR" "$LOG" | head -40
  exit 1
fi
grep -q -E "duel_|vision_done|perf_done|canopy_done|story_done|shot t01_title|check pause_closes: PASS|check manual_reached_play: PASS|shot g07_pass" "$LOG" || { echo "story did not finish"; exit 1; }
if grep -q "check .*: FAIL" "$LOG"; then echo "a control check failed"; exit 1; fi
exit 0
