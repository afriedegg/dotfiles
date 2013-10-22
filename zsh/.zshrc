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
    export PATH=/home/lukepomfrey/bin:/home/lukepomfrey/.local/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games
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
antigen-bundle bundler
antigen-bundle command-not-found
antigen-bundle debian
antigen-bundle fasd
antigen-bundle gem
antigen-bundle git
antigen-bundle git-extras
antigen-bundle git-remote-branch
#antigen-bundle github
antigen-bundle golang
antigen-bundle heroku
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
antigen-bundle $HOME/dotfiles/zsh/custom/plugins/zshmarks
antigen-theme $HOME/dotfiles/zsh/custom/lpomfrey.zsh-theme
antigen-apply

## Functions
serve_dir () {
    twistd --pidfile /tmp/twistdweb.$(date --rfc-3339=ns | sed -e "s/[^0-9]//g").pid -n web --path . --port tcp:interface=${2:-127.0.0.1}:port=${1:-8000}
}

nss_add_cert () {
    certutil -d sql:$HOME/.pki/nssdb -A -t TC -n ${1} -i ${2}
}

# Aliases
alias :q="exit"
alias ack="ack-grep"
alias collectstatic="python ./manage.py collectstatic --noinput"
alias grp="git remote | xargs -n1 git remote prune"
alias j="fasd_cd -d"
alias mc="MC_SKIN=~/.config/mc/skins/solarized.ini mc"
alias mng="python ./manage.py"
alias my_ips="internal_ips"
alias profileserver="python ./manage.py runprofileserver --kcachegrind --prof-path=${HOME}/prof/"
alias py="ipython"
alias rless="less -r"
alias runserver="python ./manage.py runserver"
alias shell_plus="python ./manage.py shell_plus"
alias ta="tmux attach -t"
alias v='f -t -e vim -b viminfo'
alias vagrant-new="vagrant init precise32 http://files.vagrantup.com/precise32.box"
alias zshreload=". ~/.zshrc"

function gaa() {
    git add $(git status --porcelain | awk '{ print $2 }')
}
function gam() {
    git add $(git status --porcelain | awk '$1 == "M" { print $2 }')
}

function pdfmin() {
    gs -sDEVICE=pdfwrite -dCompatibilityLevel-1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile="${1%.pdf}-min.pdf" "${1}"
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
PS1="$PS1"'$([ -n "$TMUX" ] && tmux setenv TMUXPWD_$(tmux display -p "#D" | tr -d %) "$PWD")'
