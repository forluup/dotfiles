# dotfiles

Personal macOS configuration files, living in `~/.config`.

## Contents

| Directory | Tool | Description |
|-----------|------|-------------|
| `zsh/` | [zsh](https://www.zsh.org) | Primary shell — oh-my-zsh, powerlevel10k, fzf/atuin/zoxide integration |
| `atuin/` | [Atuin](https://atuin.sh) | Shell history database (SQLite, synced) |
| `bat/` | [bat](https://github.com/sharkdp/bat) | `cat` replacement — `cyberpunk-neon` theme, also used as `MANPAGER` |
| `git/` | [git](https://git-scm.com) | Global ignore rules (see `~/.gitconfig` for delta setup) |
| `gh/` | [GitHub CLI](https://cli.github.com) | `gh` settings and aliases |
| `lazygit/` | [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI — pins delta to `--paging=never` for its diff pane |
| `fastfetch/` | [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info readout |
| `yabai/` | [yabai](https://github.com/koekeishiya/yabai) | Tiling window manager (BSP layout, gaps, signals) |
| `skhd/` | [skhd](https://github.com/koekeishiya/skhd) | Hotkey daemon — window focus/movement and space switching, paired with yabai |
| `sketchybar/` | [SketchyBar](https://github.com/FelixKratz/SketchyBar) | Custom status bar (`items/`, `plugins/`, `colors.sh`, `install.sh`) |
| `nvim/` | [Neovim](https://neovim.io) | Editor config (Lua, `lazy.nvim` plugin manager) |
| `fish/` | [fish](https://fishshell.com) | Secondary shell config, functions, completions |
| `linearmouse/` | [LinearMouse](https://linearmouse.app) | Mouse/pointer settings |
| `iterm2/` | [iTerm2](https://iterm2.com) | Terminal preferences |

## Setup

Clone into `~/.config`, then run the installer — it handles Homebrew, all the
tools below, oh-my-zsh, powerlevel10k, the custom zsh plugins, and the
`~/.zshenv` stub:

```sh
cd ~/.config && ./install.sh
```

Safe to re-run; it skips anything already present.

### How zsh finds this repo

`.zshrc` lives at `~/.config/zsh/.zshrc`, not `~/.zshrc`. zsh only reads
`~/.zshenv` by default, so that file is a stub pointing `ZDOTDIR` here:

```sh
export ZDOTDIR="$HOME/.config/zsh"
```

`install.sh` writes it if absent and leaves an existing one untouched. Without
it, none of the zsh config loads.

### Manual install

```sh
brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
brew install FelixKratz/formulae/sketchybar
brew install neovim fish
brew install atuin bat eza fzf fd ripgrep zoxide git-delta direnv jq gh lazygit
brew install zsh-autosuggestions zsh-history-substring-search
```

Note that four `source` lines in `.zshrc` are unguarded — oh-my-zsh,
powerlevel10k, zsh-autosuggestions and zsh-history-substring-search. A missing
one is a startup error, not a silent skip.

Then start the services:

```sh
yabai --start-service
skhd --start-service
brew services start sketchybar
```

For SketchyBar, see `sketchybar/install.sh` for fonts and dependencies.
