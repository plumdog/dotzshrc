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
alias nt='gnome-terminal "$PWD"'
alias x='exit'
alias emacs="emacs -nw"
alias v="vcsh"

function ssh-tunnel() {
	host="$1"
	ssh -C2TnN -D 8080 "$1"
}

function get-music() {
	rsync -avru pi@rpi:/home/pi/Music/ ~/Music/mp3s/
}

function put-music() {
	rsync -avru ~/Music/mp3s/ pi@rpi:/home/pi/Music/
}

PROMPT_NAME="%{$fg[blue]%}%n%{$reset_color%}"
PROMPT_HOST="%{$fg[black]%}%m%{$reset_color%}"
PROMPT_PATH="%{$fg[cyan]%}%~%{$reset_color%}"
PROMPT=$PROMPT_NAME"@"$PROMPT_HOST" "$PROMPT_PATH" %#
❯ "

RPROMPT="%(0?..[%?])"%(
