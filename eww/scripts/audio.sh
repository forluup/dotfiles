#!/usr/bin/env bash
# Sink and source levels for the dashboard sliders, as whole percentages.
# There is no /sys/class/backlight on this machine (external monitor over HDMI),
# so there is deliberately no brightness slider here.

level() { pactl "get-$1-volume" "@DEFAULT_$2@" 2>/dev/null | awk 'NR==1 {print $5}' | tr -d '%'; }
muted() { pactl "get-$1-mute"   "@DEFAULT_$2@" 2>/dev/null | awk '{print $2}'; }

vol=$(level sink SINK); mic=$(level source SOURCE)

[ "$(muted sink SINK)"     = yes ] && sink_icon=$'' || sink_icon=$''
[ "$(muted source SOURCE)" = yes ] && mic_icon=$''  || mic_icon=$''

printf '{"volume":%d,"mic":%d,"sink_icon":"%s","mic_icon":"%s"}\n' \
  "${vol:-0}" "${mic:-0}" "$sink_icon" "$mic_icon"
