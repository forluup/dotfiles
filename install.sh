#!/bin/bash

# install.sh
# Installs ALL dependencies for the tools configured in this ~/.config repo:
#   yabai, skhd, sketchybar, neovim, fish, zsh (oh-my-zsh + powerlevel10k),
#   linearmouse, iterm2, rust toolchain, and the CLI tools the zsh config
#   sources or evals at startup.
#
# Usage:
#   cd ~/.config && ./install.sh
#
# Safe to re-run: brew skips already-installed packages.

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

# --- Window manager + hotkey daemon (yabai, skhd) -----------------------------
info "Installing yabai and skhd..."
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd

# --- Shell + editor -----------------------------------------------------------
info "Installing fish and neovim..."
brew install fish
brew install neovim

# --- Neovim tooling (used by LSP, telescope, treesitter, lazygit) -------------
info "Installing Neovim support tools (ripgrep, fd, lazygit, node)..."
brew install ripgrep
brew install fd
brew install lazygit
brew install node

# --- Rust toolchain (fish sources ~/.cargo/env.fish) --------------------------
if ! command -v rustup >/dev/null 2>&1 && ! command -v cargo >/dev/null 2>&1; then
  info "Installing Rust toolchain (rustup)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
  info "Rust toolchain already installed."
fi

# --- GUI apps (cask): LinearMouse, iTerm2 -------------------------------------
info "Installing LinearMouse and iTerm2..."
brew install --cask linearmouse
brew install --cask iterm2

# --- SketchyBar + fonts -------------------------------------------------------
# Delegate to the dedicated SketchyBar installer (handles fonts, icon map, service).
if [ -x "$SCRIPT_DIR/sketchybar/install.sh" ]; then
  info "Running SketchyBar installer..."
  "$SCRIPT_DIR/sketchybar/install.sh"
else
  info "Installing SketchyBar directly..."
  brew install FelixKratz/formulae/sketchybar
fi

# --- Shell CLI tools ----------------------------------------------------------
# Everything .zshrc sources, evals, or aliases. The four `source` lines in
# .zshrc are unguarded, so a missing plugin here is a hard startup error.
info "Installing shell CLI tools..."
brew install \
  atuin bat eza fzf zoxide git-delta direnv jq gh fastfetch k9s btop \
  zsh-autosuggestions zsh-history-substring-search

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
# .zshrc sources p10k from ~/powerlevel10k, and names fzf-tab and
# zsh-syntax-highlighting in plugins=(); neither ships with oh-my-zsh.
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_once() {  # clone_once <repo-url> <dest>
  if [ -d "$2" ]; then
    info "$(basename "$2") already present."
  else
    info "Cloning $(basename "$2")..."
    git clone --depth=1 "$1" "$2"
  fi
}

clone_once https://github.com/romkatv/powerlevel10k.git         "$HOME/powerlevel10k"
clone_once https://github.com/Aloxaf/fzf-tab.git                "$ZSH_CUSTOM/plugins/fzf-tab"
clone_once https://github.com/zsh-users/zsh-syntax-highlighting.git \
                                                               "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# --- ZDOTDIR stub -------------------------------------------------------------
# zsh reads ~/.zshenv first; without this stub it never finds ~/.config/zsh
# and none of the config in this repo loads.
if [ -f "$HOME/.zshenv" ]; then
  info "~/.zshenv already exists, leaving it alone."
else
  info "Writing ~/.zshenv to point ZDOTDIR at this repo..."
  cat > "$HOME/.zshenv" <<'EOF'
# Stub: real zsh config lives in ~/.config/zsh (tracked in dev-environment-files)
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
fi

# --- Start services -----------------------------------------------------------
info "Starting services (yabai, skhd, sketchybar)..."
yabai --start-service || info "yabai service may need accessibility permissions."
skhd --start-service || true
brew services restart sketchybar || true

info "Done! All dependencies installed."
info "Note: yabai may require disabling SIP / granting permissions — see https://github.com/koekeishiya/yabai/wiki"
