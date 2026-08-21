# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git fzf-tab extract copypath copyfile sudo zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

export EDITOR=nvim VISUAL=nvim

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/p10k.zsh.
export POWERLEVEL9K_CONFIG_FILE=~/.config/zsh/p10k.zsh
[[ ! -f ~/.config/zsh/p10k.zsh ]] || source ~/.config/zsh/p10k.zsh
export PATH="$HOME/.local/bin:$PATH"

# ---- FZF -----

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# Cyberpunk neon colors (matches sketchybar teal scheme + p10k lavender)
export FZF_DEFAULT_OPTS="
  --color=bg:#001f30,bg+:#003547,fg:#e6f7f5,fg+:#ffffff
  --color=hl:#eb46f9,hl+:#eb46f9,info:#af87ff,header:#af87ff
  --color=prompt:#2cf9ed,pointer:#2cf9ed,spinner:#2cf9ed
  --color=marker:#1dfca1,border:#003547,gutter:#001f30
  --border=rounded --border-label-pos=2"

# Make fzf-tab use the same colors
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# -- Previews (bat for files, eza for dirs) --

export FZF_CTRL_T_OPTS="--border-label=' files ' --preview 'bat -n --color=always {} 2>/dev/null || eza --tree --icons --level=2 --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_ALT_C_OPTS="--border-label=' dirs ' --preview 'eza --tree --icons --level=2 --color=always {}'"

# Option-C sends 'ç' here, not ESC-c, so fzf's '\ec' binding never fires
bindkey 'ç' fzf-cd-widget
zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always $realpath 2>/dev/null || eza --tree --icons --color=always $realpath'

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# ---- Eza (better ls) -----

alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ll="eza -la --icons --git"
alias lt="eza --tree --icons --level=2"

# Cyberpunk neon colors: teal dirs, lavender symlinks/sizes, magenta executables
export EZA_COLORS="di=1;38;2;44;249;237:ln=38;2;175;135;255:ex=38;2;235;70;249:sn=38;2;175;135;255:sb=38;2;175;135;255:uu=38;2;92;122;138:un=38;2;92;122;138:da=38;2;92;122;138:ga=38;2;29;252;161:gm=38;2;249;119;22:gd=38;2;255;36;83:gv=38;2;21;189;249:ur=38;2;44;249;237:uw=38;2;235;70;249:ux=38;2;29;252;161:ue=38;2;29;252;161:gr=38;2;92;122;138:gw=38;2;92;122;138:gx=38;2;92;122;138:tr=38;2;92;122;138:tw=38;2;92;122;138:tx=38;2;92;122;138:xx=38;2;59;106;122"

# ---- Bat (better cat) -----

alias cat="bat"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ---- Zoxide (smarter cd) -----

eval "$(zoxide init zsh)"

# ---- Direnv (per-directory env) -----

eval "$(direnv hook zsh)"

# ---- Zsh syntax highlighting (cyberpunk neon) -----

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#2cf9ed'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#2cf9ed'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#2cf9ed,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#2cf9ed,bold'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#2cf9ed'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#1dfca1,italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#eb46f9'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff2453'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#af87ff'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#af87ff'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#af87ff'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#2cf9ed'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#2cf9ed'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#c4a7ff'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#c4a7ff'
ZSH_HIGHLIGHT_STYLES[path]='fg=#e6f7f5,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#eb46f9'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#eb46f9'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#eb46f9'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#eb46f9'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#5c7a8a,italic'

# Enable zsh-autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#3b6a7a'  # muted teal ghost text
[[ $commands[kubectl] && ! -f $ZSH_CACHE_DIR/completions/_kubectl ]] && kubectl completion zsh > $ZSH_CACHE_DIR/completions/_kubectl

# ---- Atuin (better history on Ctrl-R; up-arrow left to substring search) -----

eval "$(atuin init zsh --disable-up-arrow)"

# ---- Atuin's history through fzf on Ctrl-R (atuin's own TUI: `atuin search -i`) -----

atuin-fzf() {
  local sel
  sel=$(atuin search --cmd-only --print0 --limit 5000 2>/dev/null |
    fzf --read0 --height=40% --min-height=20+ --layout=reverse --scheme=history \
        --query="$LBUFFER" --border-label=' history ' \
        --preview 'bat --color=always -pl bash --style=plain <<< {}' \
        --preview-window 'down,3,wrap,border-top' \
        --bind 'focus:transform:n=$(printf %s {} | grep -c ""); echo "change-preview-window(down,$(( n < 2 ? 3 : (n > 14 ? 14 : n + 2) )),wrap,border-top)"')
  # ponytail: sizes by newline count only; a very long single-line command that
  # soft-wraps past 3 rows still gets 3. Use FZF_COLUMNS + awk length() if that bites.
  if [[ -n $sel ]]; then
    BUFFER=$sel
    CURSOR=$#BUFFER
  fi
  zle reset-prompt
}
zle -N atuin-fzf
bindkey '^R' atuin-fzf

# ---- History substring search (type a prefix, then up/down arrows) -----

source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=#003547,fg=#2cf9ed,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=#330a1e,fg=#ff2453,bold'
