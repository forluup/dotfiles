#!/bin/bash

# Hide the widget only when Spotify is closed
if ! pgrep -xq Spotify; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# Query current media information using nowplaying-cli or osascript
if command -v nowplaying-cli &> /dev/null; then
  # Use nowplaying-cli if available (recommended)
  RATE="$(nowplaying-cli get playbackRate)"
  if [ "$RATE" != "0" ]; then
    STATE="playing"
  else
    STATE="paused"
  fi
  TITLE="$(nowplaying-cli get title)"
  ARTIST="$(nowplaying-cli get artist)"
else
  # Fallback to AppleScript for Spotify. The "is running" guard checks without
  # launching, so this can't relaunch Spotify while it's quitting.
  INFO="$(osascript 2>/dev/null <<'EOF'
if application "Spotify" is running then
  tell application "Spotify"
    set s to player state as string
    set t to name of current track as string
    set a to artist of current track as string
  end tell
  return s & linefeed & t & linefeed & a
end if
EOF
)"
  if [ -z "$INFO" ]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
  fi
  STATE="$(printf '%s\n' "$INFO" | sed -n 1p)"
  TITLE="$(printf '%s\n' "$INFO" | sed -n 2p)"
  ARTIST="$(printf '%s\n' "$INFO" | sed -n 3p)"
fi

MEDIA="$TITLE - $ARTIST"

if [ "$STATE" = "playing" ]; then
  sketchybar --set "$NAME" label="$MEDIA" drawing=on scroll_texts=on
else
  # Paused: keep the widget visible, just stop the text from scrolling
  sketchybar --set "$NAME" label="$MEDIA" drawing=on scroll_texts=off
fi
