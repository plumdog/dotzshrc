# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# emacs all the things, all the time
export EDITOR='emacs'
export ALTERNATE_EDITOR=""
EDITOR_CMD="emacsclient -nw -c -t"

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
alias nt='new_terminal'
alias x='exit'
alias emacs="$EDITOR_CMD"
alias e="$EDITOR_CMD"
alias em="$EDITOR_CMD"
alias emac="$EDITOR_CMD"  # because I typo it way too often, OK?!
alias v="vcsh"
alias 'ssh-tunnel'="ssh -C2TnN -D 8080"
alias g="git"
alias s=svn
alias gs="git status"

function findr() {
    NAME="$1"
    find . -name "$NAME"
}

alias f="findr"

function sdiff() {
    svn diff $@ | colordiff | less -XFR
}

function slog() {
    svn log $@ | less -XFR
}

function new_terminal() {
    if [[ -z "$1" ]]; then
        gnome-terminal --hide-menubar "$PWD"
    elif [[ $1 == "-x" ]]; then
        shift
        args="$@"
        gnome-terminal --hide-menubar "$PWD" -x "$SHELL" -c "$args; exec $SHELL"
    else
        for i in $(seq 1 "$1"); do
            new_terminal
        done
    fi
}

function upsearch () {
	slashes=${PWD//[^\/]/}
	directory="$PWD"
	for (( n=${#slashes}; n>0; --n ))
	do
        if [[ -e "$directory/$1" ]]; then
            if [[ "$2" == "dir" ]]; then
                if [[ -d "$directory/$1" ]]; then
                    echo "$directory/$1" && return
                fi
            else
                echo "$directory/$1" && return
            fi
		fi
		directory="$directory/.."
	done

	cd "$directory"
	echo "$PWD"
	cd - >> /dev/null
}

function create_virtualenv {
    _python="$1"
    if [[ -z $_python ]]; then
        _python="python2.7"
    fi

	dir=$(upsearch '.venv' 'dir')
    if [[ "$dir" == "/" ]]; then
        dir=$(upsearch 'venv' 'dir')
    fi

	if [[ "$dir" == "/" ]]
	then
		echo "Create virtualenv"
		virtualenv venv --setuptools --python="$_python"
		source ./venv/bin/activate
	else
		echo "Activate existing virtualenv"
		source "$dir"/bin/activate
	fi
}

function emacs_ag {
    emacs $(ag -l $@)
}

alias vv='create_virtualenv'
alias vvd='deactivate'
alias emags=emacs_ag

setopt prompt_subst
. ~/.git-prompt.sh

PROMPT_NAME="%{$fg[blue]%}%n%{$reset_color%}"
PROMPT_HOST="%{$fg[green]%}%m%{$reset_color%}"
PROMPT_BRANCH=$'$(__git_ps1 " [%s]")'
PROMPT_PATH="%{$fg[cyan]%}%~%{$reset_color%}"
PROMPT=$PROMPT_NAME"@"$PROMPT_HOST$PROMPT_BRANCH" "$PROMPT_PATH" %#
❯ "



RPROMPT="%(0?..[%?])"

if [ -d "/usr/local/heroku/bin" ]; then
    export PATH="/usr/local/heroku/bin:$PATH"
fi

USERBIN="/home/$USER/bin"
if [[ -d $USERBIN ]]; then
    export PATH="$USERBIN:$PATH"
fi
