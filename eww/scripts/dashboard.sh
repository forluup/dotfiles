#!/usr/bin/env bash
# Toggle the interactive dashboard onto whichever monitor currently has focus.
# The desktop widgets sit on the bottom layer and cannot take clicks; this one
# is a foreground window, so it has to be summoned and dismissed deliberately.

screen=$(hyprctl monitors -j | jq '[.[] | select(.focused)][0].id // 0')

eww open dashboard --toggle --screen "$screen"
