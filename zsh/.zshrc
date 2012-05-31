eval `dircolors ~/.dir_colors`

xrdb -merge ~/.Xdefaults 2>&1 > /dev/null

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="lpomfrey"

# Example aliases
alias zshconfig="vi ~/.zshrc"
#alias ohmyzsh="vi ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git github debian command-not-found python django zshmarks pip fabric)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=/home/lukepomfrey/bin:/home/lukepomfrey/.local/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
export VIRTUAL_ENV_DISABLE_PROMPT=true

walkup() {
    if [ -f $1 ]; then
        echo '.'
        return 0
    fi
    d=$(dirname $PWD)
    while [ "$d" != "/" ]; do
        if [ -f "$d/$1" ]; then
            echo "$d"
            return 0
        fi
        d=$(dirname $d)
    done
    return 1
}


act () {
    if [ -n "$1" ]
    then
        if [ ! -d "$1" ]
        then
            echo "act: $1 no such directory"
            return 1
        fi
        if [ ! -e "$1/bin/activate" ]
        then
            echo "act: $1 is not a virtualenv"
            return 1
        fi
        if which deactivate > /dev/null
        then
            deactivate
        fi
        cd "$1"
        source bin/activate
    else
        virtualenv="$(walkup bin/activate)" 
        if [ $? -eq 1 ]
        then
            echo "act: not in a virtualenv"
            return 1
        fi
        source "$virtualenv"/bin/activate
    fi
}
