# dotfiles

Personal configuration files, living in `~/.config`. Cross-platform: macOS
(yabai/skhd/SketchyBar) and Arch Linux (Hyprland/waybar), sharing the same
shell, editor and CLI config and the same cyberpunk-neon palette.

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
| `nvim/` | [Neovim](https://neovim.io) | Editor config (Lua, `lazy.nvim` plugin manager) |
| `fish/` | [fish](https://fishshell.com) | Secondary shell config, functions, completions |

### macOS only

| Directory | Tool | Description |
|-----------|------|-------------|
| `yabai/` | [yabai](https://github.com/koekeishiya/yabai) | Tiling window manager (BSP layout, gaps, signals) |
| `skhd/` | [skhd](https://github.com/koekeishiya/skhd) | Hotkey daemon — window focus/movement and space switching, paired with yabai |
| `sketchybar/` | [SketchyBar](https://github.com/FelixKratz/SketchyBar) | Custom status bar (`items/`, `plugins/`, `colors.sh`, `install.sh`) |
| `linearmouse/` | [LinearMouse](https://linearmouse.app) | Mouse/pointer settings |
| `iterm2/` | [iTerm2](https://iterm2.com) | Terminal preferences |

### Linux only (Hyprland)

| Directory | Tool | Description |
|-----------|------|-------------|
| `hypr/` | [Hyprland](https://hyprland.org) | Tiling compositor — `hyprland.conf` (ports yabai + skhd), `hyprlock.conf`, `hypridle.conf`, `gaps.sh` |
| `waybar/` | [Waybar](https://github.com/Alexays/Waybar) | Status bar — a port of the SketchyBar layout and teal scheme |
| `wofi/` | [wofi](https://hg.sr.ht/~scoopta/wofi) | Launcher (Spotlight replacement) and clipboard-history picker |
| `mako/` | [mako](https://github.com/emersion/mako) | Notification daemon |
| `ghostty/` | [Ghostty](https://ghostty.org) | Terminal (iTerm2 replacement) |

## Setup

Clone into `~/.config`, then run the installer for your platform. Both handle
every tool listed above plus oh-my-zsh, powerlevel10k, the custom zsh plugins
and the `~/.zshenv` stub (the shared parts live in `zsh/install.sh`):

```sh
cd ~/.config && ./install-mac.sh    # macOS  — Homebrew, yabai, skhd, sketchybar
cd ~/.config && ./install-arch.sh   # Arch   — paru, hyprland, waybar, ghostty
```

Safe to re-run; both skip anything already present.

### Bootstrapping a fresh Arch box

From the TTY of a working Arch install, with a network:

```sh
sudo pacman -Syu --needed git                                              # the only prereq
git clone https://github.com/forluup/dev-environment-files.git ~/.config   # HTTPS: no SSH key yet
cd ~/.config && ./install-arch.sh
```

Then log out of the TTY and back in — `install-arch.sh` runs `chsh`, so zsh
only becomes the login shell on the next session — and start the compositor:

```sh
exec Hyprland
```

If `~/.config` already has files in it, step 2 fails: git won't clone into a
non-empty directory. Graft the repo on instead. This overwrites any colliding
file with the repo's version:

```sh
git clone --no-checkout https://github.com/forluup/dev-environment-files.git /tmp/cfg
mv /tmp/cfg/.git ~/.config/ && rm -rf /tmp/cfg
cd ~/.config && git reset --hard origin/main
```

Four things the installer leaves to you, because they need credentials or
interactive time. Run them once you're inside Hyprland:

```sh
nvim                    # lazy.nvim + mason bootstrap on first launch; wait, then :q
atuin login             # the synced history db
gh auth login           # gh/hosts.yml is gitignored, so auth is always fresh
ssh-keygen -t ed25519 && git remote set-url origin git@github.com:forluup/dev-environment-files.git
```

No display manager is installed — login is a TTY plus `exec Hyprland`. Add
greetd or uwsm if you want a graphical login.

### How zsh finds this repo

`.zshrc` lives at `~/.config/zsh/.zshrc`, not `~/.zshrc`. zsh only reads
`~/.zshenv` by default, so that file is a stub pointing `ZDOTDIR` here:

```sh
export ZDOTDIR="$HOME/.config/zsh"
```

`zsh/install.sh` writes it if absent and leaves an existing one untouched. Without
it, none of the zsh config loads.

### Linux: how the macOS keybinds map over

`hypr/hyprland.conf` keeps the muscle memory 1:1 — macOS `cmd` becomes `SUPER`
(`$launch`), macOS `alt` becomes `ALT` (`$mod`). Both are variables at the top
of the file, so swapping them is a two-line change.

| macOS (skhd) | Linux (Hyprland) | Notes |
|---|---|---|
| `cmd+return` iTerm | `SUPER+Return` ghostty | |
| `cmd+shift+return` Chrome | `SUPER+SHIFT+Return` | |
| — | `SUPER+Space` | wofi, the Spotlight replacement |
| `alt+hjkl` focus | `ALT+hjkl` `movefocus` | the display-warp fallback is gone; Hyprland crosses monitors and warps the cursor natively |
| `alt+1..0` space | `ALT+1..0` workspace | |
| `alt+shift+1..0` send | `ALT+SHIFT+1..0` | |
| `alt+shift+hjkl` swap | `ALT+SHIFT+hjkl` `swapwindow` | |
| `cmd+shift+hjkl` warp | `SUPER+SHIFT+hjkl` `movewindow` | |
| `alt+x` close | `ALT+X` `killactive` | |
| `alt+e` toggle split | `ALT+E` `togglesplit` | |
| `alt+f` zoom-fullscreen | `ALT+F` `fullscreen 1` | maximize inside the gaps |
| `alt+shift+f` native fullscreen | `ALT+SHIFT+F` `fullscreen 0` | |
| `alt+d` zoom-parent | `ALT+D` `pseudo` | closest dwindle equivalent |
| `alt+t` float + center | `ALT+T` | one batched `togglefloating` + resize + center |
| `alt+n` / `alt+shift+n` new space | `ALT+N` / `ALT+SHIFT+N` `empty` | workspaces are dynamic here |
| `alt+a` toggle gaps | `ALT+A` → `hypr/gaps.sh toggle` | |
| `alt+g` / `alt+shift+g` gap ± | `ALT+G` / `ALT+SHIFT+G` | |
| `ctrl+alt+d` float layout | `CTRL+ALT+D` `workspaceopt allfloat` | toggles, so `ctrl+alt+a` (bsp) is dropped |
| `ctrl+alt+hjkl` resize | `CTRL+ALT+hjkl` `resizeactive` | h/l and j/k already grow *and* shrink, so the `ctrl+alt+cmd` group is dropped |
| `ctrl+alt+cmd+r` restart yabai | `CTRL+ALT+SUPER+R` `hyprctl reload` | |
| `cmd+shift+4` / `3` screenshot | `SUPER+SHIFT+4` / `3` | grim + slurp → `wl-copy` |
| `ctrl+cmd+q` lock | `SUPER+CTRL+Q` hyprlock | |
| — | `SUPER+V` | cliphist clipboard history |

Four skhd binds have no Hyprland counterpart and were dropped: `alt+q`
(`space --destroy` — workspaces are dynamic), `alt+y` (`mirror y-axis`),
`alt+r` (`rotate 90`) and `alt+shift+e` (`balance`); dwindle has no mirror,
rotate or balance message.

Also gone, because Hyprland or Wayland does it natively: yabai's
`external_bar` reservation (waybar reserves its own space via layer-shell),
`auto_balance off` (the default), and the `window_minimized` focus-fix signal
(a macOS bug that doesn't exist here).

Not ported: `linearmouse/` (no Linux equivalent — pointer and touchpad settings
live in `hyprland.conf`'s `input {}` block) and `iterm2/` (which only ever held
gitignored machine-local symlinks).

### Manual install

macOS:

```sh
brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd
brew install FelixKratz/formulae/sketchybar
brew install neovim fish
brew install atuin bat eza fzf fd ripgrep zoxide git-delta direnv jq gh lazygit
brew install zsh-autosuggestions zsh-history-substring-search
```

Arch:

```sh
paru -S hyprland hyprlock hypridle waybar wofi mako ghostty
paru -S grim slurp wl-clipboard cliphist swayosd-git playerctl brightnessctl
paru -S neovim fish ttf-hack-nerd
paru -S atuin bat eza fzf fd ripgrep zoxide git-delta direnv jq github-cli lazygit
paru -S zsh-autosuggestions zsh-history-substring-search
```

Note that four `source` lines in `.zshrc` are unguarded — oh-my-zsh,
powerlevel10k, zsh-autosuggestions and zsh-history-substring-search. A missing
one is a startup error, not a silent skip. The last two resolve through
`$ZSH_PLUGINS`, which follows `$HOMEBREW_PREFIX` on macOS and falls back to
`/usr/share/zsh/plugins` on Arch.

Then start the services — macOS:

```sh
yabai --start-service
skhd --start-service
brew services start sketchybar
```

For SketchyBar, see `sketchybar/install.sh` for fonts and dependencies.

On Arch there is nothing to start: waybar, mako, hypridle and swayosd-server
are all launched from `exec-once` lines in `hypr/hyprland.conf`. The only
systemd units are `NetworkManager` and `swayosd-libinput-backend` (which lets
the volume/brightness keys work without root).
