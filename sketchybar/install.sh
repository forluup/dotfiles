#!/bin/bash

# install.sh
# Installs all dependencies required to get this SketchyBar configuration working.
# Based on https://www.josean.com/posts/sketchybar-setup
#
# Usage:
#   cd ~/.config/sketchybar && ./install.sh
#
# Safe to re-run: brew skips already-installed packages and we only re-download
# the app font / icon map if they are missing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf "\033[1;34m==>\033[0m %s\n" "$1"; }

# --- Homebrew -----------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  info "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Make brew available in the current shell (Apple Silicon vs Intel paths).
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  info "Homebrew already installed."
fi

# --- SketchyBar ---------------------------------------------------------------
info "Installing SketchyBar..."
brew tap FelixKratz/formulae
brew install sketchybar

# --- Command-line tools used by the config scripts ----------------------------
info "Installing CLI dependencies (jq, nowplaying-cli)..."
brew install jq
brew install nowplaying-cli

# --- Fonts --------------------------------------------------------------------
info "Installing fonts..."
brew install --cask font-hack-nerd-font
brew install --cask font-sf-pro
brew install --cask sf-symbols

# sketchybar-app-font: provides the app icons used by icon_map_fn.sh
APP_FONT="$HOME/Library/Fonts/sketchybar-app-font.ttf"
if [ ! -f "$APP_FONT" ]; then
  info "Downloading sketchybar-app-font..."
  curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.30/sketchybar-app-font.ttf \
    -o "$APP_FONT"
else
  info "sketchybar-app-font already present."
fi

# --- Icon map function --------------------------------------------------------
# The repo already ships plugins/icon_map_fn.sh. Only fetch it if it's missing.
ICON_MAP="$SCRIPT_DIR/plugins/icon_map_fn.sh"
if [ ! -f "$ICON_MAP" ]; then
  info "Downloading icon_map_fn.sh..."
  curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.30/icon_map.sh \
    -o "$ICON_MAP"
else
  info "icon_map_fn.sh already present (shipped with repo)."
fi

# --- Make scripts executable --------------------------------------------------
info "Making config scripts executable..."
chmod +x "$SCRIPT_DIR/sketchybarrc"
chmod +x "$SCRIPT_DIR"/plugins/*.sh
chmod +x "$SCRIPT_DIR"/items/*.sh 2>/dev/null || true

# --- Start / restart the SketchyBar service -----------------------------------
info "Starting SketchyBar service..."
brew services restart sketchybar

info "Done! SketchyBar is installed and running."
info "If the bar doesn't appear, grant any requested permissions and run: brew services restart sketchybar"
