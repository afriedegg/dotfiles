if [ -n "$DISPLAY" -a "$TERM"=="xterm" ]; then
    export TERM=xterm-256color
fi

if [ -n "$DISPLAY" -a -f ~/.xsession ]; then
    . ~/.xsession
fi

eval `dircolors ~/.dir_colors`

# Exports
if (( ! $+VIRTUAL_ENV )) || (( ! $+PATH )); then
    # In if to ensure we don't fuck up pew shells
    export PATH=/home/lukepomfrey/bin:/home/lukepomfrey/.local/bin:/usr/lib/lightdm/lightdm:/usr/local/heroku/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
fi
export EDITOR=vi

ANTIGEN=$HOME/dotfiles/zsh/antigen

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
antigen-use oh-my-zsh
antigen-bundle command-not-found
antigen-bundle debian
antigen-bundle django
antigen-bundle fasd
antigen-bundle gem
antigen-bundle git
antigen-bundle git-extras
antigen-bundle golang
antigen-bundle heroku
antigen-bundle mosh
antigen-bundle node
antigen-bundle npm
antigen-bundle pip
antigen-bundle python
antigen-bundle supervisor
antigen-bundle tmux
antigen-bundle vagrant
antigen-bundle virtualenv
antigen-bundle virtualenvwrapper
antigen-bundle vundle
antigen-bundle wakeonlan
antigen-bundle zsh-users/zsh-syntax-highlighting
antigen-bundle $HOME/dotfiles/zsh/custom/plugins/fabric
antigen-bundle $HOME/dotfiles/zsh/custom/plugins/virtualbox
antigen-bundle $HOME/dotfiles/zsh/custom/plugins/zshmarks
#antigen-theme $HOME/dotfiles/zsh/custom/lpomfrey.zsh-theme
antigen-apply

source $HOME/.local/lib/python2.7/site-packages/powerline/bindings/zsh/powerline.zsh

## Functions
serve_dir () {
    twistd --pidfile /tmp/twistdweb.$(date --rfc-3339=ns | sed -e "s/[^0-9]//g").pid -n web --path . --port tcp:interface=${2:-127.0.0.1}:port=${1:-8000}
}

nss_add_cert () {
    certutil -d sql:$HOME/.pki/nssdb -A -t TC -n ${1} -i ${2}
}

start_tmux () {
    # Expects $TMUX_SESSIONS to be a list of sessions, e.g
    # TMUX_SESSIONS=("session1" "session2" "session3")
    printf "Starting tmux...\n"
    tmux start-server
    for session in $TMUX_SESSIONS; do
        printf "Starting session %s...\n" "${session}"
        tmux has-session -t ${session} 2>/dev/null || tmux new-session -d -s ${session} 2>/dev/null
        printf "Running teamocil for %s...\n" "${session}"
        tmux run-shell -t ${session}:1 "teamocil --here ${session}" 2>&1 >/dev/null
    done
    printf "Waiting for sessions to start."
    for i in {1..9}; do
        sleep 1
        printf "."
    done
    sleep 1
    printf "\nAttaching to tmux...\n"
    tmux attach
}

tmux_refresh () {
    if [[ -n $TMUX ]]; then
        NEW_SSH_AUTH_SOCK=`tmux showenv|grep ^SSH_AUTH_SOCK|cut -d = -f 2`
        if [[ -n $NEW_SSH_AUTH_SOCK ]] && [[ -S $NEW_SSH_AUTH_SOCK ]]; then 
            export SSH_AUTH_SOCK=$NEW_SSH_AUTH_SOCK  
        fi
        NEW_GPG_AGENT_INFO=`tmux showenv|grep ^GPG_AGENT_INFO|cut -d = -f 2`
        if [[ -n $NEW_GPG_AGENT_INFO ]] && [[ -S $NEW_GPG_AGENT_INFO ]]; then 
            export GPG_AGENT_INFO=$NEW_GPG_AGENT_INFO  
        fi
        NEW_GNOME_KEYRING_CONTROL=`tmux showenv|grep ^GNOME_KEYRING_CONTROL|cut -d = -f 2`
        if [[ -n $NEW_GNOME_KEYRING_CONTROL ]] && [[ -S $NEW_GNOME_KEYRING_CONTROL ]]; then 
            export GNOME_KEYRING_CONTROL=$NEW_GNOME_KEYRING_CONTROL  
        fi
        NEW_DISPLAY=`tmux showenv|grep ^DISPLAY|cut -d = -f 2`
        if [[ -n $NEW_DISPLAY ]]; then 
            export DISPLAY=$NEW_DISPLAY  
        fi
        NEW_SSH_ASKPASS=`tmux showenv|grep ^SSH_ASKPASS|cut -d = -f 2`
        if [[ -n $NEW_SSH_ASKPASS ]]; then 
            export SSH_ASKPASS=$NEW_SSH_ASKPASS  
        fi
        NEW_SSH_AGENT_PID=`tmux showenv|grep ^SSH_AGENT_PID|cut -d = -f 2`
        if [[ -n $NEW_SSH_AGENT_PID ]]; then 
            export SSH_AGENT_PID=$NEW_SSH_AGENT_PID  
        fi
        NEW_SSH_CONNECTION=`tmux showenv|grep ^SSH_CONNECTION|cut -d = -f 2`
        if [[ -n $NEW_SSH_CONNECTION ]]; then 
            export SSH_CONNECTION=$NEW_SSH_CONNECTION  
        fi
        NEW_WINDOWID=`tmux showenv|grep ^WINDOWID|cut -d = -f 2`
        if [[ -n $NEW_WINDOWID ]]; then 
            export WINDOWID=$NEW_WINDOWID  
        fi
        NEW_XAUTHORITY=`tmux showenv|grep ^XAUTHORITY|cut -d = -f 2`
        if [[ -n $NEW_XAUTHORITY ]]; then 
            export XAUTHORITY=$NEW_XAUTHORITY  
        fi
        NEW_GNOME_KEYRING_PID=`tmux showenv|grep ^GNOME_KEYRING_PID|cut -d = -f 2`
        if [[ -n $NEW_GNOME_KEYRING_PID ]]; then 
            export GNOME_KEYRING_PID=$NEW_GNOME_KEYRING_PID  
        fi
        NEW_GNOME_DESKTOP_SESSION_ID=`tmux showenv|grep ^GNOME_DESKTOP_SESSION_ID|cut -d = -f 2`
        if [[ -n $NEW_GNOME_DESKTOP_SESSION_ID ]]; then 
            export GNOME_DESKTOP_SESSION_ID=$NEW_GNOME_DESKTOP_SESSION_ID  
        fi
    fi
}

function unusedipscan() {
    # Find unused IPs in a given range
    nmap -v -sn ${1:-192.168.0.0/16} | grep "\[host down\]" | awk '{print $5}'
}

function gaa() {
    git add --all
}
function gam() {
    git add $(git status --porcelain | awk '$1 == "M" { print $2 }')
}

function pdfmin() {
    gs -sDEVICE=pdfwrite -dCompatibilityLevel-1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile="${1%.pdf}-min.pdf" "${1}"
}

function psgrep() {
    ps -ef | grep "$(echo $1 | sed 's/^\(.\)/\[\1\]/')"
}

# Aliases
alias :q="exit"
alias ack="ack-grep"
alias collectstatic="python ./manage.py collectstatic --noinput"
alias grp="git remote | xargs -n1 git remote prune"
alias j="fasd_cd -d"
alias mc="MC_SKIN=~/.config/mc/skins/solarized.ini mc"
alias mng="python ./manage.py"
alias profileserver="python ./manage.py runprofileserver --kcachegrind --prof-path=${HOME}/prof/"
alias pubip="dig +short myip.opendns.com @resolver1.opendns.com"
alias py="ipython"
alias rless="less -r"
alias runserver="python ./manage.py runserver"
alias shell_plus="python ./manage.py shell_plus"
alias ta="tmux attach -t"
alias v='f -t -e vim -b viminfo'
alias vagrant-new="vagrant init precise32 http://files.vagrantup.com/precise32.box"
alias vboxheadless="VBoxHeadless"
alias vboxmanage="VBoxManage"
alias zshreload=". ~/.zshrc"

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

autoload bashcompinit
bashcompinit
for file in $HOME/dotfiles/zsh/custom/bashcomp/*.bash; do
    source ${file}
done

if [ -f ~/.zshrc.local ] ; then
    source ~/.zshrc.local
fi

bindkey '^[OA' up-line-or-search
bindkey '^[OB' down-line-or-search

# Sets PS1 for tmux
_powerline_tmux_setenv() {
    emulate -L zsh
    if [[ -n "$TMUX" ]]; then
        tmux setenv -g TMUX_"$1"_$(tmux display -p "#D" | tr -d %) "$2"
        tmux refresh -S
    fi
}

_powerline_tmux_set_pwd() {
    _powerline_tmux_setenv PWD "$PWD"
}

_powerline_tmux_set_columns() {
    _powerline_tmux_setenv COLUMNS "$COLUMNS"
}
PS1="$PS1"'$(_powerline_tmux_set_pwd)'
