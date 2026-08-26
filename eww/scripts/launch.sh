#!/usr/bin/env bash
# Open the always-on desktop widgets on every connected monitor. An eww window
# is a single instance, so eww.yuck defines a second copy of each (suffixed -2)
# pinned to monitor 1; open that set only when a second monitor is present.

eww daemon >/dev/null 2>&1

eww open-many clock resources media

if [ "$(hyprctl monitors | grep -c '^Monitor ')" -ge 2 ]; then
  eww open-many clock-2 resources-2 media-2
fi
