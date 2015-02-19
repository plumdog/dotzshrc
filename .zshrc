# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# emacs all the things, all the time
export EDITOR='emacs'

# Use modern completion system
autoload -Uz compinit
compinit

# load colors
autoload -U colors && colors

# functions and aliases
alias less='less -XF'
alias ls='ls --color'
alias ll='ls -alF'
alias l='ls -CF'
alias nt='gnome-terminal "$PWD"'
alias x='exit'
alias emacs="emacsclient -nw"
alias e="emacsclient -nw"
alias v="vcsh"
alias 'ssh-tunnel'="ssh -C2TnN -D 8080"
alias g="git"

function upsearch () {
	slashes=${PWD//[^\/]/}
	directory="$PWD"
	for (( n=${#slashes}; n>0; --n ))
	do
		test -e "$directory/$1" && echo "$directory/$1" && return
		directory="$directory/.."
	done

	cd "$directory"
	echo "$PWD"
	cd - >> /dev/null
}

function create_virtualenv {
	dir=$(upsearch 'venv')

	if [[ "$dir" == "/" ]]
	then
		echo "Create virtualenv"
		virtualenv venv --setuptools
		source ./venv/bin/activate
	else
		echo "Activate existing virtualenv"
		source "$dir"/bin/activate
	fi
}

alias vv='create_virtualenv'
alias vvd='deactivate'


PROMPT_NAME="%{$fg[blue]%}%n%{$reset_color%}"
PROMPT_HOST="%{$fg[green]%}%m%{$reset_color%}"
PROMPT_PATH="%{$fg[cyan]%}%~%{$reset_color%}"
PROMPT=$PROMPT_NAME"@"$PROMPT_HOST" "$PROMPT_PATH" %#
❯ "

RPROMPT="%(0?..[%?])"%(
