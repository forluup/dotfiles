# dotfiles

Personal macOS configuration files, living in `~/.config`.

## Contents

| Directory | Tool | Description |
|-----------|------|-------------|
| `yabai/` | [yabai](https://github.com/koekeishiya/yabai) | Tiling window manager (BSP layout, gaps, signals) |
| `skhd/` | [skhd](https://github.com/koekeishiya/skhd) | Hotkey daemon — window focus/movement and space switching, paired with yabai |
| `sketchybar/` | [SketchyBar](https://github.com/FelixKratz/SketchyBar) | Custom status bar (`items/`, `plugins/`, `colors.sh`, `install.sh`) |
| `nvim/` | [Neovim](https://neovim.io) | Editor config (Lua, `lazy.nvim` plugin manager) |
| `fish/` | [fish](https://fishshell.com) | Shell config, functions, completions |
| `linearmouse/` | [LinearMouse](https://linearmouse.app) | Mouse/pointer settings |
| `iterm2/` | [iTerm2](https://iterm2.com) | Terminal preferences |
| `cagent/` | — | Agent config |

## Setup

These files are intended to be symlinked or cloned directly into `~/.config`.
Install the underlying tools first (most are available via [Homebrew](https://brew.sh)):

```sh
brew install koekeishiya/formulae/yabai
brew install koekeishiya/formulae/skhd
brew install FelixKratz/formulae/sketchybar
brew install neovim fish
```

Then start the services:

```sh
yabai --start-service
skhd --start-service
brew services start sketchybar
```

For SketchyBar, see `sketchybar/install.sh` for fonts and dependencies.
