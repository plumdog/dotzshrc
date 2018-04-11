# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# emacs all the things, all the time
export ALTERNATE_EDITOR=""
EDITOR_CMD="emacsclient -nw -c -t"
export EDITOR="$EDITOR_CMD"
export VISUAL="$EDITOR_CMD"

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
alias naut="nautilus --no-desktop"

export CC=gcc
export CXX="g++"

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

NOTEPATH_BASE=~/Dropbox/notes

function notes_tabbed {
    printf "%s\t%s\n" "Note" "LastMod"
    printf "%s\t%s\n" "----" "-------"
    notes=$(cd "$NOTEPATH_BASE" && find . -name '*.txt' ! -path './_**' | sort)
    while read -r note; do
        name=$(basename "$note" | sed -e 's/.txt$//')
        # chop out the decimal places in the timestamp
        lastmod=$(stat -c %y "$note" | sed -e 's/\..* / /')
        printf "%s\t%s\n" "$name" "$lastmod"
    done <<< "$notes"
}

function notes {
    notes_tabbed | column -t -s "$(printf '\t')"
}

function get_note_path {
    if [[ -z "$1" ]]; then
        PS3="Note: "
        select NOTE in $(cd "$NOTEPATH_BASE" && find . -name '*.txt' ! -path './_**' -exec basename {} \; | sort | sed -e 's/.txt//'); do
            echo "Selected: $REPLY) $NOTE"
            note="$NOTE"
            break
        done
    else
        note="$1"
    fi

    if [[ -n "$note" ]]; then
        NOTEPATH="$NOTEPATH_BASE"/"$note".txt
    fi
}

function notecat {
    NOTEPATH=""
    get_note_path "$1"
    if [[ -z "$1" ]]; then
        echo "############"
    fi
    if [[ -n NOTE ]]; then
        cat "$NOTEPATH"
    fi
}

function note {
    NOTEPATH=""
    get_note_path "$1"
    if [[ -n $NOTEPATH ]]; then
        emacs "$NOTEPATH"
    fi
}

function notepdf {
    notename="$1"
    title="$2"
    if [[ -z $title ]]; then
        title="$notename"
    fi
    tempdir="$(mktemp -d)"
    sourcefile="notes_content"
    notecat "$notename" > "$tempdir/notes.md"
    basetex="$tempdir/notes.tex"

    cat "$NOTEPATH_BASE/_base.tex" > "$basetex"
    sed -i -e 's/TITLE/'"$title"'/' "$basetex"
    sed -i -e 's/DATE/'"$(date +'%B %d, %Y')"'/' "$basetex"
    sed -i -e 's/SOURCEFILE/'"$sourcefile"'/' "$basetex"
    cp "$NOTEPATH_BASE/_makefile" "$tempdir/Makefile"
    (cd "$tempdir" && make)

    pdfpath="$tempdir/notes.pdf"

    if [[ -f "$pdfpath" ]]; then
        evince "$pdfpath"
    else
        echo "Error generating pdf"
    fi

    rm -rf "$tempdir"
}

function noteslides {
    SLIDES_THEME="${2:-simple}"

    NOTEPATH=""
    get_note_path "$1"
    notename="$(basename "$NOTEPATH" | sed 's/\.txt$//')"
    ( cd "$NOTEPATH_BASE" &&
          docker run --rm -i \
                 --user "$(id -u)":"$(id -g)" \
                 -v "$(pwd)":/pandoc \
                 geometalab/pandoc pandoc \
                 -t revealjs \
                 -s \
                 -o "$notename".html \
                 "$notename".txt \
                 -V revealjs-url=http://lab.hakim.se/reveal-js \
                 -V width=1920 \
                 -V height=1080 \
                 -V theme="$SLIDES_THEME" &&
          google-chrome "$notename".html
    )
}

function battery {
    upower -i $(upower -e | grep 'BAT') | grep 'percentage' | sed -e 's/^.*:\s*//'
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

EXTRA_PATHS=(
    /usr/local/heroku/bin
    /snap/bin
    /home/$USER/bin
)

for p in "${EXTRA_PATHS[@]}"; do
    PATH="$p:$PATH"
done

export PATH="$PATH"

if which kubectl &> /dev/null; then
    source <(kubectl completion zsh)
fi
