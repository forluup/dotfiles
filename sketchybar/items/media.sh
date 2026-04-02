#!/bin/bash

sketchybar --add item media e \
           --set media drawing=on \
                       position=left \
                       offset=-20 \
                       label.color=$ACCENT_COLOR \
                       label.max_chars=35 \
                       scroll_texts=on \
                       icon=􀑪 \
                       icon.color=$ACCENT_COLOR \
                       background.drawing=off \
                       script="$PLUGIN_DIR/media.sh" \
           --subscribe media media_change spotify_change

