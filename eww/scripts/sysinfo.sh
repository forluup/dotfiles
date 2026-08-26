#!/usr/bin/env bash
# Identity and system facts for the profile card.

up=$(uptime -p | sed 's/^up //; s/ days\?/d/; s/ hours\?/h/; s/ minutes\?/m/; s/,//g; s/ //g')

printf '{"user":"%s","host":"%s","uptime":"%s","kernel":"%s","pkgs":"%s"}\n' \
  "$(whoami)" "$(hostnamectl hostname 2>/dev/null || uname -n)" \
  "$up" "$(uname -r | cut -d- -f1)" "$(pacman -Qq | wc -l)"
