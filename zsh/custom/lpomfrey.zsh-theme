# vim: set filetype=zsh :
autoload -U colors && colors

 

virtualenv_info() {
    [ $VIRTUAL_ENV ] || return
    echo "$VENV_PROMPT_BEFORE$(basename $VIRTUAL_ENV)$VENV_PROMPT_AFTER"
}

show_time() {
    if (( $COLUMNS > 100 )); then
        date --rfc-3339=seconds
    elif (( $COLUMNS > 60 )); then
        echo "%*"
    fi
}

hg_prompt_info() {
    if (( $termcap[colors] > 128 )) || [[ $TERM == "xterm-256color" ]]; then
        hg prompt --angle-brackets \
"${HG_PROMPT_BEFORE}<branch>< %{$fg_bold[red]%}<status> %{$fg_no_bold[yellow]%}>${HG_PROMPT_AFTER}" 2> /dev/null
    else
        hg prompt --angle-brackets \
"${HG_PROMPT_BEFORE}<branch>< %{$fg_bold[red]%}<status>%{$reset_color%}>${HG_PROMPT_AFTER}" 2> /dev/null
    fi
}

if (( $termcap[colors] > 128 )) || [[ $TERM == "xterm-256color" ]]; then
    VENV_PROMPT_BEFORE="%{$fg_no_bold[yellow]%}%{$bg[yellow]%} %{$fg_no_bold[white]%}venv: %{$fg_bold[white]%}"
    VENV_PROMPT_AFTER="%{$fg_no_bold[yellow]%}%{$bg[yellow]%} %{$fg_no_bold[white]%}"
    HG_PROMPT_BEFORE="%{$fg_no_bold[white]%}%{$bg[white]%}%{$fg_no_bold[yellow]%} hg: "
    HG_PROMPT_AFTER="%{$fg_no_bold[white]%}"
    ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_no_bold[green]%}%{$bg[green]%}%{$fg_no_bold[white]%} git: %{$fg_bold[white]%}"
    ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg_no_bold[green]%} "
    ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg_bold[red]%}!!%{$fg_no_bold[white]%}"
    ZSH_THEME_GIT_PROMPT_CLEAN=""
    PROMPT='%{${BG[024]}%}%{$fg_no_bold[white]%}%n@%m %{$reset_color%}%{$bg[blue]%}%{${FG[024]}%}⮀ \
%{$fg_bold[white]%}%$(( $COLUMNS / 3 ))<..<${PWD/#$HOME/~} %{$reset_color%}%{$fg_no_bold[blue]%}⮀ %{$reset_color%}'
    RPROMPT='%(1j.%{$fg_no_bold[red]%}%{$bg[red]%}%{$fg[white]%} jobs: %{$fg_bold[white]%}%j%{$fg_no_bold[red]%}%{$bg[red]%}%{$fg[white]%}.)\
$(virtualenv_info)$(git_prompt_info)$(hg_prompt_info)%{$fg[grey]%}%{$bg[grey]%}%{$fg[white]%} $(show_time)%{$reset_color%}'
else
    VENV_PROMPT_BEFORE="%{$fg_no_bold[blue]%}venv:(%{$fg_no_bold[yellow]%}"
    VENV_PROMPT_AFTER="%{$fg_no_bold[blue]%}) %{$reset_color%}"
    HG_PROMPT_BEFORE="%{$fg_no_bold[grey]%}hg:(%{$fg_no_bold[yellow]%}"
    HG_PROMPT_AFTER="%{$fg_no_bold[grey]%}) %{$reset_color%}"
    ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_no_bold[magenta]%}git%{$fg_no_bold[magenta]%}:(%{$fg_no_bold[yellow]%}"
    ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
    ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg_bold[red]%}!%{$reset_color%}%{$fg_no_bold[magenta]%})"
    ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_no_bold[magenta]%})"
    PROMPT='%{$fg_no_bold[yellow]%}%n%{$reset_color%}%{$fg_no_bold[yellow]%}@%m%{$reset_color%}%{$fg_no_bold[cyan]%}:%{$reset_color%}%{$fg_no_bold[cyan]%}%$(( $COLUMNS / 3 ))<..<${PWD/#$HOME/~}$ %{$reset_color%}'
    RPROMPT='%(1j.%{$fg_no_bold[red]%}jobs:(%{$fg_no_bold[yellow]%}%j%{$fg_no_bold[red]%}) .)%{$reset_color%}$(virtualenv_info)%{$reset_color%}$(hg_prompt_info)$(git_prompt_info)%{$reset_color%}$(show_time)%{$reset_color%}'
fi



ZSH_THEME_TERM_TITLE_IDLE="%n@%m: %d"  # Prevent env vars appearing in title
ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%d%<<"

export VIRTUAL_ENV_DISABLE_PROMPT=true
