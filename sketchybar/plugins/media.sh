#!/bin/bash

# Query current media information using nowplaying-cli or osascript
if command -v nowplaying-cli &> /dev/null; then
  # Use nowplaying-cli if available (recommended)
  STATE="$(nowplaying-cli get playbackRate)"
  if [ "$STATE" != "0" ]; then
    TITLE="$(nowplaying-cli get title)"
    ARTIST="$(nowplaying-cli get artist)"
    MEDIA="$TITLE - $ARTIST"
    sketchybar --set "$NAME" label="$MEDIA"
  else
    sketchybar --set "$NAME" label=""
  fi
else
  # Fallback to AppleScript for Spotify
  STATE="$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)"
  if [ "$STATE" = "playing" ]; then
    TITLE="$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null)"
    ARTIST="$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null)"
    MEDIA="$TITLE - $ARTIST"
    sketchybar --set "$NAME" label="$MEDIA"
  else
    sketchybar --set "$NAME" label=""
  fi
fi
