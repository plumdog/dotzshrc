# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# emacs all the things, all the time
export EDITOR='emacs'

# Use modern completion system
autoload -Uz compinit
compinit

# load colors
autoload -U colors && colors

# functions and aliases
alias ls='ls --color'
alias ll='ls -alF'
alias l='ls -CF'
alias nt='gnome-terminal "$PWD"'
alias x='exit'
alias emacs="emacs -nw"
alias e="emacs"
alias v="vcsh"
alias 'ssh-tunnel'="ssh -C2TnN -D 8080"
alias g="git"

PROMPT_NAME="%{$fg[blue]%}%n%{$reset_color%}"
PROMPT_HOST="%{$fg[black]%}%m%{$reset_color%}"
PROMPT_PATH="%{$fg[cyan]%}%~%{$reset_color%}"
PROMPT=$PROMPT_NAME"@"$PROMPT_HOST" "$PROMPT_PATH" %#
❯ "

RPROMPT="%(0?..[%?])"%(
