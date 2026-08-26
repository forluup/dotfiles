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
# A helper that exists but cannot run is worse than none, so test it rather
# than trusting `command -v`. The -bin packages are compiled against one
# libalpm soname, so any pacman upgrade that bumps it leaves them dying with
# "libalpm.so.NN: cannot open shared object file".
aur_works() { command -v "$1" >/dev/null 2>&1 && "$1" --version >/dev/null 2>&1; }

if aur_works paru; then
  AUR=paru
elif aur_works yay; then
  AUR=yay
else
  if command -v paru >/dev/null 2>&1 || command -v yay >/dev/null 2>&1; then
    info "An AUR helper is installed but will not run — usually a libalpm"
    info "soname mismatch after a pacman upgrade. Replacing it..."
  else
    info "Installing paru..."
  fi

  # Clear out the prebuilt packages unconditionally, not just when a helper
  # binary is still on PATH: a half-removed -bin install leaves the -debug
  # package behind with no binary, and it owns /usr/lib/debug/usr/bin/*.debug,
  # which fails the rebuilt package with a file-conflict error.
  #
  # One name per transaction, because pacman -R aborts the whole thing if any
  # named target is not installed. -Rdd because nothing depends on a helper.
  for helper in paru-bin paru-bin-debug yay-bin yay-bin-debug; do
    if pacman -Qq "$helper" >/dev/null 2>&1; then
      info "Removing stale $helper..."
      sudo pacman -Rdd --noconfirm "$helper" || true
    fi
  done

  # Source `paru`, not `paru-bin`: it compiles against the libalpm actually
  # installed on this machine, so it survives the pacman upgrades that break
  # the prebuilt package. Costs a Rust build once.
  sudo pacman -S --needed --noconfirm base-devel git
  tmp="$(mktemp -d)"
  git clone --depth=1 https://aur.archlinux.org/paru.git "$tmp/paru"
  (cd "$tmp/paru" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  AUR=paru
fi
info "Using $AUR."

# --- NVIDIA -------------------------------------------------------------------
# Only runs on a machine with an NVIDIA GPU, so this stays a no-op elsewhere.
#
# nvidia-open, not nvidia: the open kernel modules are the only ones that
# support Turing and newer, and on Blackwell (RTX 50xx) they are the sole
# option — the legacy proprietary module has no Blackwell support at all.
#
# Wayland needs DRM modesetting, which means the modules go in the initramfs
# and nvidia_drm.modeset=1 on the kernel command line. The driver package
# ships a pacman hook that rebuilds the initramfs on driver updates, but the
# MODULES= edit below is ours, so mkinitcpio runs here once.
if lspci -nn | grep -qi 'nvidia'; then
  info "NVIDIA GPU detected. Installing nvidia-open..."
  $AUR -S --needed --noconfirm nvidia-open nvidia-utils

  # Kernel modules into the initramfs.
  if ! grep -q '^MODULES=.*nvidia' /etc/mkinitcpio.conf; then
    info "Adding the nvidia modules to mkinitcpio.conf..."
    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak
    sudo sed -i -E \
      's/^MODULES=\(([^)]*)\)/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/; s/^MODULES=\( /MODULES=(/' \
      /etc/mkinitcpio.conf
    sudo mkinitcpio -P
  else
    info "mkinitcpio.conf already lists the nvidia modules."
  fi

  # DRM modesetting on the kernel command line.
  if ! grep -q 'nvidia_drm.modeset=1' /etc/default/grub; then
    info "Adding nvidia_drm.modeset=1 to the kernel command line..."
    sudo cp /etc/default/grub /etc/default/grub.bak
    sudo sed -i -E \
      's/^(GRUB_CMDLINE_LINUX_DEFAULT=")([^"]*)"/\1\2 nvidia_drm.modeset=1"/' \
      /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  else
    info "Kernel command line already sets nvidia_drm.modeset=1."
  fi

  NVIDIA_REBOOT=1
fi

# --- Hyprland desktop ---------------------------------------------------------
# Replaces yabai (hyprland), skhd (hyprland binds), sketchybar (waybar),
# Spotlight (wofi), Notification Center (mako), and macOS screenshot/lock.
info "Installing the Hyprland desktop..."
$AUR -S --needed --noconfirm \
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland \
  waybar wofi mako eww \
  grim slurp wl-clipboard cliphist swayosd-git \
  polkit-gnome qt5-wayland qt6-wayland playerctl \
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
  ripgrep fd lazygit nodejs npm \
  git curl unzip python python-pip

# Rust: rustup and Arch's `rust` package conflict, and `rust` already ships a
# working rustc/cargo. Only reach for rustup when neither is installed.
if pacman -Qq rust >/dev/null 2>&1; then
  info "Arch's rust package is installed; skipping rustup."
else
  $AUR -S --needed --noconfirm rustup
  # Arch's rustup package ships no toolchain (the rustup.rs installer on macOS
  # picks stable for you).
  if ! rustup toolchain list | grep -q .; then
    info "Installing the stable Rust toolchain..."
    rustup default stable
  fi
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
# Lets swayosd-client read the volume keys without root.
sudo systemctl enable --now swayosd-libinput-backend.service || \
  info "swayosd-libinput-backend not available; media keys still work via hyprland binds."
systemctl --user enable --now pipewire pipewire-pulse wireplumber || true

if [ -n "${NVIDIA_REBOOT:-}" ]; then
  info "The NVIDIA driver was just installed: reboot before starting Hyprland,"
  info "so the kernel modules and nvidia_drm.modeset=1 actually take effect."
fi

info "Done! Log out and start Hyprland (\`Hyprland\` from a TTY, or pick it in your display manager)."
info "First keys to try: SUPER+Return terminal, SUPER+Space launcher, ALT+1..0 workspaces."
