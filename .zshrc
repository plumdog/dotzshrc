# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# emacs all the things, all the time
export ALTERNATE_EDITOR=""
EDITOR_CMD="emacsclient -nw"
export EDITOR="$EDITOR_CMD"
export VISUAL="$EDITOR_CMD"
export BROWSER=firefox
export GPG_TTY=$(tty)

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
        _python="python3"
    fi

    

    dir=$(upsearch '.venv' 'dir')
    if [[ "$dir" == "/" ]]; then
        dir=$(upsearch 'venv' 'dir')
    fi

	if [[ "$dir" == "/" ]]
	then
		echo "Create virtualenv"
                $_python -m venv venv || virtualenv -p $_python venv
		source ./venv/bin/activate
                pip install -U pip wheel
                if [[ -f Pipfile ]]; then
                    pip install pipenv
                    pipenv sync
                elif [[ -f requirements.txt ]]; then
                    pip install -r requirements.txt;
                fi
	else
		echo "Activate existing virtualenv"
		source "$dir"/bin/activate
	fi
}

function autocompletes {
    # echo "Loading completions"
    if which kubectl &> /dev/null; then
        source <(kubectl completion zsh)
        # echo "Loaded kubectl completion"
    fi

    if which kops &> /dev/null; then
        source <(kops completion zsh)
        # echo "Loaded kops completion"
    fi

    if which helm &> /dev/null; then
        source <(helm completion zsh)
        # echo "Loaded helm completion"
        export HELM_DIFF_COLOR=true
    fi
    if which aws_completer &> /dev/null; then
        complete -C $(which aws_completer) aws
    fi

    if [[ -f /etc/bash_completion.d/azure-cli ]]; then
        source /etc/bash_completion.d/azure-cli
    fi

    if [[ -f package.json ]]; then
        source <(npm completion)
    fi
}


function emacs_ag {
    emacs -c $(ag -l $@)
}

function day_start_uptime {
    date -ud "@$(($(date +%s) - $(date +%s --date="$(last --time-format iso --since $(date -I) | head -n -2 | sed 's/ - .*//' | sed 's/.*\('"$(date +%Y)"'[0-9T:+\-]*\).*/\1/' | sort | head -n 1)")))" +'%-H:%M:%S'
}

alias uptimeday=day_start_uptime

function share_screen {
    monitor_num="${1:-1}"

    line="$(xrandr -q | grep ' connected' | sed "${monitor_num}q;d")"

    if [[ -z $line ]]; then
        >&2 echo "No such screen"
        return 1;
    fi

    size_and_offset="$(echo "$line" | sed -r 's/^.* ([0-9]+x[0-9]+\+[0-9]+\+[0-9]+) .*$/\1/')"


    size="$(echo "$size_and_offset" | sed 's/+.*//')"
    offset="$(echo "$size_and_offset" | sed 's/[^+]*+//')"

    x_size="$(echo "$size" | cut -f 1 -dx)"
    y_size="$(echo "$size" | cut -f 2 -dx)"

    x_offset="$(echo "$offset" | cut -f 1 -d+)"
    y_offset="$(echo "$offset" | cut -f 2 -d+)"

    echo $x_size $y_size $x_offset $y_offset

    toolbar_height=32

    cvlc --no-video-deco --no-embedded-video --screen-fps=20 --screen-top=$(($y_offset + $toolbar_height)) --screen-left=$x_offset --screen-width=$x_size --screen-height=$(($y_size - $toolbar_height)) --video-title=sharescreen screen://
}

NOTEPATH_BASE=~/Dropbox/notes

function _get_notes {
    (cd "$NOTEPATH_BASE" && find . -name '*.txt' ! -path './_**' | sed -e 's/"/"\\""/g' -e 's/.*/"&"/' | xargs -L 1 basename | sort)
}

function _notes_tabbed {
    printf "%s\t%s\n" "Note" "LastMod"
    printf "%s\t%s\n" "----" "-------"
    while read -r note; do
        name=$(echo "$note" | sed -e 's/\.txt$//')
        # chop out the decimal places in the timestamp
        lastmod=$(stat -c %y "$NOTEPATH_BASE/$note" | sed -e 's/\..* / /')
        printf "%s\t%s\n" "$name" "$lastmod"
    done <<< "$(_get_notes)"
}

function notes {
    _notes_tabbed | column -t -s "$(printf '\t')"
}

function get_note_path {
    if [[ -z "$1" ]]; then
        PS3="Note: "
        select NOTE in $(_get_notes | sed -e 's/.txt//'); do
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



function note_autocomplete {
    local -a notes_array
    notes_array=($(_get_notes | sed 's/\.txt//'))
    _describe 'command' notes_array
}

function title_case {
    sed 's/.*/\L&/; s/[a-z]*/\u&/g'
}

function from_underscores {
    sed 's/[^a-zA-Z0-9]/ /g'
}

function notepdf {
    notename="$1"
    title="$2"
    if [[ -z $title ]]; then
        title="$(echo "$notename" | from_underscores | title_case)"
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

function notetextile {
    NOTEPATH=""
    get_note_path "$1"
    fname="$(basename "$NOTEPATH")"
    ( cd "$NOTEPATH_BASE" &&
          docker run --rm -i \
                 --user "$(id -u)":"$(id -g)" \
                 -v "$(pwd)":/pandoc \
                 geometalab/pandoc pandoc \
                 -t textile \
                 "$fname" )
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
                 --slide-level 2 \
                 -V revealjs-url=https://unpkg.com/reveal.js@3.9.2/ \
                 -V width=1920 \
                 -V height=1080 \
                 -V theme="$SLIDES_THEME" &&
          firefox "$notename".html
    )
}

function battery {
    upower -i $(upower -e | grep 'BAT') | grep 'percentage' | sed -e 's/^.*:\s*//'
}

function to_qwerty {
    setxkbmap -layout gb
}

function act {
    if [[ ! -f ./bin/activate ]]; then
        echo "No ./bin/activate, not running"
        return 1
    fi

    if [[ -f .nvmrc || -f package.json ]]; then
        if [[ -f .nvmrc ]]; then
            nvm install || echo "Failed to install node/npm based on .nvmrc file"
            export PATH="$PATH"
        else
            echo "No .nvmrc, trying to determine node version from package.json"
            node_version_range="$(cat package.json | jq -r '.engines.node // ""')"
            if [[ -n $node_version_range ]]; then
                echo "Found node version range: $node_version_range"
                all_node_versions="$(curl --silent 'https://nodejs.org/dist/index.json' | jq -r '.[] | .version' | sed 's/^v//' | grep 14 | xargs)"
                setopt shwordsplit
                resolved_node_version="$(npx semver -r "$node_version_range" $all_node_versions | tail -n 1)"
                unsetopt shwordsplit
                echo "Resolved version range to $resolved_node_version, installing"
                nvm install "$resolved_node_version"
            fi
        fi
        npm_version="$(cat package.json | jq -r '.engines.npm // ""')"
        if [[ -n $npm_version ]]; then
            npm i -g npm@"$npm_version"
        else
            echo "Installing latest that works with node"
            nvm install-latest-npm
        fi
        echo "done"
    fi

    if head -n 1 ./bin/activate | grep 'python' >> /dev/null; then
        create_virtualenv && {
                env_vars="$(./bin/activate $@)"
                source <(echo "$env_vars")
            }
    else
        env_vars="$(./bin/activate $@)"
        source <(echo "$env_vars")
    fi

    autocompletes
}

alias vv='create_virtualenv'
alias vvd='deactivate'
alias emags=emacs_ag

function csv_less {
    column -s, -t < $@ | less -#2 -N -S
}

yq_docker() {
    docker run --rm -i -v "${PWD}":/workdir mikefarah/yq:4.25.1 "$@"
}

alias csvl=csv_less

setopt prompt_subst
. ~/.git-prompt.sh

PROMPT_NAME="%{$fg[blue]%}%n%{$reset_color%}"
PROMPT_HOST="%B%{$fg[green]%}%m%{$reset_color%}%b"
PROMPT_BRANCH=$'$(__git_ps1 " [%s]")'
PROMPT_PATH="%{$fg[cyan]%}%~%{$reset_color%}"
PROMPT=$PROMPT_NAME"@"$PROMPT_HOST$PROMPT_BRANCH" "$PROMPT_PATH" %#
❯ "

RPROMPT="%(0?..%{$fg[red]%}[%?]%{$reset_color%})"

EXTRA_PATHS=(
    /usr/local/heroku/bin
    /snap/bin
    /home/$USER/bin
    $HOME/.pulumi/bin
)

for p in "${EXTRA_PATHS[@]}"; do
    PATH="$p:$PATH"
done

export PATH="$PATH"

export PS1="$PS1"

if [[ -f /usr/share/nvm/init-nvm.sh ]]; then
    source /usr/share/nvm/init-nvm.sh
fi

# For some reason, whatever init-nvm.sh is doing upsets this
# completion definition, so this needs to come after.
compdef git

export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    . "$NVM_DIR/nvm.sh" --no-use  # This loads nvm
    nvm use --lts --silent || {
        echo "Getting some baseline node versions..."
        nvm install node --no-progress
        nvm use node --silent
        nvm install --lts --no-progress
        nvm use --silent --lts
    }
fi

if [[ -f /home/$USER/.zshrc_extra ]]; then
      source /home/$USER/.zshrc_extra
fi

compdef note_autocomplete note notecat noteslides notepdf notetextile

autocompletes

autoload bashcompinit && bashcompinit
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 24h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi
