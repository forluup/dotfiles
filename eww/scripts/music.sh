#!/usr/bin/env bash
# Now-playing state for the music card: title, artist, transport glyph and a
# local path to the album art. MPRIS hands back a remote URL for Spotify, so it
# gets cached to disk first — GTK can only use a local file as background-image.

cache="$HOME/.cache/eww/album-art"
mkdir -p "$(dirname "$cache")"

status=$(playerctl status 2>/dev/null)
if [ -z "$status" ]; then
  printf '{"title":"Nothing playing","artist":"","glyph":"","art":""}\n'
  exit 0
fi

meta() { playerctl metadata --format "$1" 2>/dev/null; }
art=$(meta '{{mpris:artUrl}}')

case "$art" in
  http*)
    # only re-download when the track actually changed
    if [ "$(cat "$cache.url" 2>/dev/null)" != "$art" ]; then
      curl -sf --max-time 5 -o "$cache" "$art" && printf '%s' "$art" > "$cache.url"
    fi
    art="$cache" ;;
  file://*) art="${art#file://}" ;;
  *) art="" ;;
esac

[ "$status" = "Playing" ] && glyph=$'' || glyph=$''

jq -nc --arg t "$(meta '{{title}}')" --arg a "$(meta '{{artist}}')" \
       --arg g "$glyph" --arg art "$art" \
  '{title: $t, artist: $a, glyph: $g, art: $art}'
