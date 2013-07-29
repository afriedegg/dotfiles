if [ -n "$DISPLAY" -a "$TERM"=="xterm" ]; then
    export TERM=xterm-256color
fi

if [ -n "$DISPLAY" -a -f ~/.xsession ]; then
    . ~/.xsession
fi

eval `dircolors ~/.dir_colors`

# Exports
export PATH=/home/lukepomfrey/bin:/home/lukepomfrey/.local/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
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
antigen-bundle bundler
antigen-bundle command-not-found
antigen-bundle debian
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
antigen-bundle tmux
antigen-bundle virtualenv
antigen-bundle virtualenvwrapper
antigen-bundle vundle
antigen-bundle wakeonlan
antigen-bundle zsh-users/zsh-syntax-highlighting
antigen-bundle $HOME/dotfiles/zsh/custom/plugins/fabric
antigen-bundle $HOME/dotfiles/zsh/custom/plugins/zshmarks
antigen-theme $HOME/dotfiles/zsh/custom/lpomfrey.zsh-theme
antigen-apply

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

internal_ips () {
    echo $(ifconfig | grep "inet " | awk '{ print $2 }')
    return 0
}


my_ip () {
    echo $(internal_ips | awk '{ print $1 }' | sed -e 's/addr://g')
    return 0
}

serve_dir () {
    twistd --pidfile /tmp/twistdweb.$(date --rfc-3339=ns | sed -e "s/[^0-9]//g").pid -n web --path . --port tcp:interface=${2:-127.0.0.1}:port=${1:-8000}
}

nss_add_cert () {
    certutil -d sql:$HOME/.pki/nssdb -A -t TC -n ${1} -i ${2}
}

if [[ ${TMUX:+intmux} == "intmux" ]]; then
    # Runs the specified command (provided by the first argument) in all tmux panes
    # for every window regardless if applications are running in the terminal or not.
    execute_in_all_panes () {

        # Notate which window/pane we were originally at
        ORIG_WINDOW_INDEX=`tmux display-message -p '#I'`
        ORIG_PANE_INDEX=`tmux display-message -p '#P'`

        # Assign the argument to something readable
        command=$1

        # Count how many windows we have
        windows=$((`tmux list-windows | wc -l` - 1))

        # Loop through the windows
        for (( window=0; window <= $windows; window++ )); do
            tmux select-window -t $window #select the window

            # Count how many panes there are in the window
            panes=$((`tmux list-panes| wc -l` - 1))
            # debugging
            #echo "window:$window pane:$pane";
            #sleep 1

            # Loop through the panes that are in the window
            for (( pane=0; pane <= $panes; pane++ )); do
                # Skip the window that the command was ran in, run it in that window last
                # since we don't want to suspend the script that we are currently running
                # and also we want to end back where we started..
                if [ $ORIG_WINDOW_INDEX -eq $window -a $ORIG_PANE_INDEX -eq $pane ]; then
                    continue
                fi
                tmux select-pane -t $pane #select the pane
                # Send the escape key, in the case we are in a vim like program. This is
                # repeated because the send-key command is not waiting for vim to complete
                # its action... also sending a sleep 1 command seems to fuck up the loop.
                for i in {1..25}; do tmux send-keys C-[; done
                # temp suspend any gui thats running
                tmux send-keys C-z
                # if no gui was running, remove the escape sequence we just sent ^Z
                tmux send-keys C-H
                # run the command & switch back to the gui if there was any
                tmux send-keys "$command && fg 2>/dev/null" C-m
            done
        done

        tmux select-window -t $ORIG_WINDOW_INDEX #select the original window
        tmux select-pane -t $ORIG_PANE_INDEX #select the original pane
        # Send the escape key, in the case we are in a vim like program. This is
        # repeated because the send-key command is not waiting for vim to complete
        # its action... also sending a sleep 1 command seems to fuck up the loop.
        for i in {1..25}; do tmux send-keys C-[; done
        # temp suspend any gui thats running
        # run the command & switch back to the gui if there was any
        tmux send-keys C-c "$command && fg 2>/dev/null" C-m
        tmux send-keys "clear" C-m

    }
fi

# Aliases
alias :q="exit"
alias ack="ack-grep"
alias collectstatic="python ./manage.py collectstatic --noinput"
alias j="fasd_cd -d"
alias mc="MC_SKIN=~/.config/mc/skins/solarized.ini mc"
alias mng="python ./manage.py"
alias my_ips="internal_ips"
alias profileserver="python ./manage.py runprofileserver --kcachegrind --prof-path=${HOME}/prof/"
alias py="ipython"
alias runserver="python ./manage.py runserver"
alias shell_plus="python ./manage.py shell_plus"
alias ta="tmux attach -t"
alias v='f -t -e vim -b viminfo'
alias zshreload=". ~/.zshrc"

function gaa() {
    git add $(git status --porcelain | awk '{ print $2 }')
}
function gam() {
    git add $(git status --porcelain | awk '$1 == "M" { print $2 }')
}

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
