#!/bin/bash

# install-arch.sh
# Arch Linux installer — the Hyprland counterpart to install-mac.sh.
# Installs the Wayland desktop (hyprland, waybar, wofi, mako, hyprlock,
# hypridle, swayosd, ghostty) plus every CLI tool the zsh config sources.
#
# Usage:
#   cd ~/.config && ./install-arch.sh
#
# Safe to re-run: --needed skips already-installed packages.
#
# Everything goes through an AUR helper rather than pacman, so repo and AUR
# packages are one list and nothing has to be sorted by origin.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf "\033[1;34m==>\033[0m %s\n" "$1"; }

# --- AUR helper ---------------------------------------------------------------
if command -v paru >/dev/null 2>&1; then
  AUR=paru
elif command -v yay >/dev/null 2>&1; then
  AUR=yay
else
  info "No AUR helper found. Bootstrapping paru..."
  sudo pacman -S --needed --noconfirm base-devel git
  tmp="$(mktemp -d)"
  git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  AUR=paru
fi
info "Using $AUR."

# --- Hyprland desktop ---------------------------------------------------------
# Replaces yabai (hyprland), skhd (hyprland binds), sketchybar (waybar),
# Spotlight (wofi), Notification Center (mako), and macOS screenshot/lock.
info "Installing the Hyprland desktop..."
$AUR -S --needed --noconfirm \
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland \
  waybar wofi mako \
  grim slurp wl-clipboard cliphist swayosd-git \
  polkit-gnome qt5-wayland qt6-wayland brightnessctl playerctl \
  pipewire pipewire-pulse pipewire-alsa wireplumber pavucontrol \
  networkmanager network-manager-applet \
  ttf-hack-nerd

# --- GUI apps -----------------------------------------------------------------
# ghostty replaces iTerm2. LinearMouse has no Linux equivalent — pointer
# settings live in hypr/hyprland.conf's input {} block instead.
info "Installing GUI apps (ghostty, chrome)..."
$AUR -S --needed --noconfirm ghostty google-chrome

# --- Shell CLI tools ----------------------------------------------------------
# Everything .zshrc sources, evals, or aliases, plus the Neovim tooling.
# The `source` lines in .zshrc are unguarded, so a missing plugin here is a
# hard startup error.
info "Installing shell CLI tools..."
$AUR -S --needed --noconfirm \
  zsh neovim fish \
  atuin bat eza fzf zoxide git-delta direnv jq github-cli fastfetch k9s btop \
  zsh-autosuggestions zsh-history-substring-search \
  ripgrep fd lazygit nodejs npm rustup \
  git curl unzip python python-pip

# Arch's rustup package ships no toolchain (the rustup.rs installer on macOS
# picks stable for you), and nvim's mason installs black/isort/pylint via pip.
if ! rustup toolchain list | grep -q .; then
  info "Installing the stable Rust toolchain..."
  rustup default stable
fi

# --- zsh: oh-my-zsh, powerlevel10k, plugins, ZDOTDIR stub ---------------------
info "Running zsh installer..."
"$SCRIPT_DIR/zsh/install.sh"

if [ "$SHELL" != "$(command -v zsh)" ]; then
  info "Setting zsh as the login shell..."
  chsh -s "$(command -v zsh)"
fi

# --- Make config scripts executable -------------------------------------------
chmod +x "$SCRIPT_DIR/hypr/gaps.sh"

# --- Services -----------------------------------------------------------------
# waybar, mako, hypridle and swayosd-server are launched by hyprland's
# exec-once, so only the system-level pieces need systemd.
info "Enabling services..."
# Don't fight whatever archinstall set up: enabling NetworkManager alongside a
# running systemd-networkd means two daemons on one interface, i.e. no network.
if systemctl is-active --quiet systemd-networkd || systemctl is-active --quiet iwd; then
  info "systemd-networkd/iwd is already managing the network; leaving it alone."
else
  sudo systemctl enable --now NetworkManager
fi
# Lets swayosd-client read volume/brightness keys without root.
sudo systemctl enable --now swayosd-libinput-backend.service || \
  info "swayosd-libinput-backend not available; media keys still work via hyprland binds."
systemctl --user enable --now pipewire pipewire-pulse wireplumber || true

info "Done! Log out and start Hyprland (\`Hyprland\` from a TTY, or pick it in your display manager)."
info "First keys to try: SUPER+Return terminal, SUPER+Space launcher, ALT+1..0 workspaces."
