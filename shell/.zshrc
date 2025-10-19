# Homebrew path
eval "$(/opt/homebrew/bin/brew shellenv)"

### Antidote --start--
# ${ZDOTDIR:-~}/.zshrc
# Set the root name of the plugins files (.txt and .zsh) antidote will use.
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins

# Ensure the .zsh_plugins.txt file exists so you can add plugins.
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt

# Ensure Antidote's functions dir from Homebrew is in $fpath
fpath+=("$(brew --prefix antidote)/share/antidote/functions")

# Load the antidote function
autoload -Uz antidote

# 1) Init completion BEFORE sourcing plugins (so compdef exists)
autoload -Uz compinit bashcompinit
# optional: use a dedicated dumpfile to avoid clashes
compinit -d "${ZDOTDIR:-$HOME}/.zcompdump-antidote"

# 2) Build & source the static bundle whenever .zsh_plugins is updated
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi
source ${zsh_plugins}.zsh
### Antidote --end--

# Load completions (for autocomplete)
autoload -U compinit && compinit
# Keybindings Completions
bindkey -v # vim style keybindings
# bindkey '^f' autosuggest-accep
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'
zstyle ':completion:*' menu no
# fzf preview
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# History
HISTSIZE=1000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ------------------------------------------------------------
# Vi mode cursor shape control (safe conditional version)
# ------------------------------------------------------------

# Enable Vi mode (if you want Emacs mode, comment this out)
# bindkey -v (done before)

# Only apply cursor logic when Vi mode is active
if [[ $KEYMAP == viins || $KEYMAP == vicmd || -n ${ZSH_VERSION-} ]]; then

  # --- Cursor helpers using xterm DECSCUSR sequences ---
  # 0/1 = blinking block, 2 = steady block
  # 3/4 = blinking underline / steady underline
  # 5/6 = blinking bar / steady bar
  _cursor_block() { printf '\e[2 q'; }   # block (normal mode)
  _cursor_bar()   { printf '\e[6 q'; }   # bar (insert mode)

  # --- Change cursor when switching keymaps ---
  function zle-keymap-select {
    case $KEYMAP in
      vicmd) _cursor_block ;;     # Normal mode → block
      viins|main) _cursor_bar ;;  # Insert mode → bar
    esac
  }
  zle -N zle-keymap-select

  # --- Initialize cursor shape when ZLE starts ---
  function zle-line-init {
    zle -K viins
    _cursor_bar
  }
  zle -N zle-line-init

  # --- Reset cursor on shell exit (optional) ---
  autoload -Uz add-zsh-hook
  add-zsh-hook zshexit _cursor_block
fi


# oh-my-posh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  # eval "$(oh-my-posh init zsh --config atomic)"
  eval "$(oh-my-posh init zsh --config '~/.config/ohmyposh/atomicBen.toml')"
fi

# Aliases
alias ls="eza --icons=always"
# alias ls="eza --no-filesize --long --color=always --no-user --icons=always"
alias c='clear'
alias ll='ls -long --color=always --no-user --icons=always'
alias cd="z"

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"


# Yazi configuration, call it with y
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Source local environment
[ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"
