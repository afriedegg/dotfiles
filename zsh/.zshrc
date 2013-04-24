if [ -n "$DISPLAY" -a "$TERM"=="xterm" ]; then
    export TERM=xterm-256color
fi

if [ -n "$DISPLAY" -a -f ~/.xsession ]; then
    . ~/.xsession
fi

eval `dircolors ~/.dir_colors`

# Path to your oh-my-zsh configuration.
#ZSH=$HOME/dotfiles/zsh/.oh-my-zsh
ANTIGEN=$HOME/dotfiles/zsh/antigen

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="lpomfrey"

# Example aliases
alias zshconfig="vi ~/.zshrc"
alias zshreload=". ~/.zshrc"
#alias ohmyzsh="vi ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

source $ANTIGEN/antigen.zsh
antigen-lib
antigen-use oh-my-zsh
antigen-bundle bundler
antigen-bundle command-not-found
antigen-bundle debian
antigen-bundle django
antigen-bundle fasd
antigen-bundle gem
antigen-bundle git
antigen-bundle git-extras
antigen-bundle git-remote-branch
antigen-bundle github
antigen-bundle golang
antigen-bundle heroku
antigen-bundle pip
antigen-bundle python
antigen-bundle supervisor
antigen-bundle urltools
antigen-bundle virtualenv
antigen-bundle virtualenvwrapper
antigen-bundle vundle
antigen-bundle zsh-users/zsh-syntax-highlighting
antigen-bundle zsh-users/zsh-completions
antigen-bundle $HOME/dotfiles/zsh/custom/plugins/fabric
antigen-bundle $HOME/dotfiles/zsh/custom/plugins/zshmarks
antigen-theme $HOME/dotfiles/zsh/custom/lpomfrey.zsh-theme
antigen-apply

# Exports
export PATH=/home/lukepomfrey/bin:/home/lukepomfrey/.local/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
export EDITOR=vi

# Functions
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

internal_ips () {
    echo $(ifconfig | grep "inet " | awk '{ print $2 }')
    return 0
}


my_ip () {
    echo $(internal_ips | awk '{ print $1 }' | sed -e 's/addr://g')
    return 0
}

serve_dir() {
    twistd --pidfile /tmp/twistdweb.$(date --rfc-3339=ns | sed -e "s/[^0-9]//g").pid -n web --path . --port tcp:interface=${2:-127.0.0.1}:port=${1:-8000}
}

nss_add_cert () {
    certutil -d sql:$HOME/.pki/nssdb -A -t TC -n ${1} -i ${2}
}

# Aliases
alias v='f -t -e vim -b viminfo'
alias j="fasd_cd -d"
alias my_ips="internal_ips"
alias mng="python ./manage.py"
alias runserver="python ./manage.py runserver"
alias shell_plus="python ./manage.py shell_plus"
alias collectstatic="python ./manage.py collectstatic --noinput"
alias profileserver="python ./manage.py runprofileserver --kcachegrind --prof-path=${HOME}/prof/"
alias ta="tmux attach -t"
alias tn="tmux new -s"
alias tna="tmux new -t"
alias tsw="tmux switch -t"
alias :q="exit"

# Disable autocorrect
if [ -f ~/.zsh_nocorrect ]; then
    while read -r COMMAND; do
        alias $COMMAND="nocorrect $COMMAND"
    done < ~/.zsh_nocorrect
fi

# Completion
if [[ ${TMUX:+intmux} == "intmux" ]]; then
    compctl -g '~/.teamocil/*(:t:r)' teamocil
fi

if [ -f ~/.zshrc.local ] ; then
    source ~/.zshrc.local
fi

bindkey '^[OA' up-line-or-search
bindkey '^[OB' down-line-or-search

# Sets PS1 for tmux
PS1="$PS1"'$([ -n "$TMUX" ] && tmux setenv TMUXPWD_$(tmux display -p "#D" | tr -d %) "$PWD")'
