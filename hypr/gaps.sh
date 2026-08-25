#!/bin/sh
# gaps.sh {toggle|+|-} — window gap control (alt-a, alt-g, shift+alt-g).
#
# Hyprland has no gap toggle and parsing the current value back out of
# `hyprctl getoption` is fiddlier than just remembering it, so state lives here.
#
# Self-check: DRY=1 sh gaps.sh toggle   (prints the hyprctl call, runs nothing)

STATE="${XDG_RUNTIME_DIR:-/tmp}/hypr-gaps"
IN=$(cat "$STATE" 2>/dev/null || echo 3)

case "$1" in
  toggle) [ "$IN" -eq 0 ] && IN=3 || IN=0 ;;
  +)      IN=$((IN + 2)) ;;
  -)      IN=$((IN - 2)); [ "$IN" -lt 0 ] && IN=0 ;;
  *)      echo "usage: gaps.sh {toggle|+|-}" >&2; exit 1 ;;
esac

echo "$IN" > "$STATE"
[ "$IN" -eq 0 ] && OUT="0 0 0 0" || OUT="11 7 7 7"

${DRY:+echo} hyprctl --batch "keyword general:gaps_in $IN ; keyword general:gaps_out $OUT"
