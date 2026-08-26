#!/bin/sh
# gaps.sh {toggle|+|-} — window gap control (alt-a, alt-g, shift+alt-g).
#
# Hyprland has no gap toggle and parsing the current value back out of
# `hyprctl getoption` is fiddlier than just remembering it, so state lives here.
#
# Only gaps_in is tracked; gaps_out is derived from it so the outer margin grows
# and shrinks along with the inner one. The +4 offset reproduces the config's
# base of gaps_in=3 / gaps_out=7,7,7,7 when IN is 3. All four sides are equal:
# waybar's margin-top supplies the space above the bar, so a bigger top gap
# here would leave more room under the bar than over it.
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

# gaps_out takes four values and hyprctl only parses them when they are
# comma-separated — spaces silently collapse to the first value on all sides.
if [ "$IN" -eq 0 ]; then
  OUT="0,0,0,0"
else
  OUT="$((IN + 4)),$((IN + 4)),$((IN + 4)),$((IN + 4))"
fi

${DRY:+echo} hyprctl --batch "keyword general:gaps_in $IN ; keyword general:gaps_out $OUT"
