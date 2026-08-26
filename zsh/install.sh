#!/bin/bash

# zsh/install.sh
# Everything the zsh config needs that isn't a distro package: oh-my-zsh, the
# powerlevel10k theme, the two custom plugins .zshrc names, and the ~/.zshenv
# stub that points ZDOTDIR here. Platform-agnostic — called by both install.sh
# (macOS) and install-arch.sh (Linux).
#
# Safe to re-run: skips anything already present.

set -euo pipefail

info() { printf "\033[1;34m==>\033[0m %s\n" "$1"; }

# --- oh-my-zsh ----------------------------------------------------------------
# --keep-zshrc is essential: this repo owns .zshrc, the installer must not
# replace it with its own template.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended --keep-zshrc
else
  info "oh-my-zsh already installed."
fi

# --- powerlevel10k + custom zsh plugins ---------------------------------------
# .zshrc sets ZSH_THEME=powerlevel10k/powerlevel10k, which oh-my-zsh resolves
# under $ZSH_CUSTOM/themes, and names fzf-tab and zsh-syntax-highlighting in
# plugins=(); none of them ship with oh-my-zsh.
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_once() {  # clone_once <repo-url> <dest>
  if [ -d "$2" ]; then
    info "$(basename "$2") already present."
  else
    info "Cloning $(basename "$2")..."
    git clone --depth=1 "$1" "$2"
  fi
}

clone_once https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
clone_once https://github.com/Aloxaf/fzf-tab.git         "$ZSH_CUSTOM/plugins/fzf-tab"
clone_once https://github.com/zsh-users/zsh-syntax-highlighting.git \
                                                        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# --- ZDOTDIR stub -------------------------------------------------------------
# zsh reads ~/.zshenv first; without this stub it never finds ~/.config/zsh
# and none of the config in this repo loads.
if [ -f "$HOME/.zshenv" ]; then
  info "~/.zshenv already exists, leaving it alone."
else
  info "Writing ~/.zshenv to point ZDOTDIR at this repo..."
  cat > "$HOME/.zshenv" <<'STUB'
# Stub: real zsh config lives in ~/.config/zsh (tracked in dotfiles)
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
STUB
fi

info "zsh setup done."
