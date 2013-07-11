autoload -U colors && colors

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_no_bold[magenta]%}%{$bg[magenta]%}%{$fg_no_bold[white]%} git: %{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg_no_bold[magenta]%} "
#ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg_no_bold[red]%}✗%{$reset_color%}%{$fg_no_bold[magenta]%})"
#ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg_no_bold[green]%}✓%{$reset_color%}%{$fg_no_bold[magenta]%})"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$bg[white]%}%{$fg_bold[red]%}!%{$bg[magenta]%}%{$fg_no_bold[white]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

virtualenv_info() {
    [ $VIRTUAL_ENV ] || return
    echo "$VENV_PROMPT_BEFORE$(basename $VIRTUAL_ENV)$VENV_PROMPT_AFTER"
}

VENV_PROMPT_BEFORE="%{$fg_no_bold[blue]%}%{$bg[blue]%} %{$fg_no_bold[white]%}venv: %{$fg_bold[white]%}"
VENV_PROMPT_AFTER="%{$fg_no_bold[blue]%}%{$bg[blue]%} %{$fg_no_bold[white]%}"

show_time() {
    if (( $COLUMNS > 100 )); then
        date --rfc-3339=seconds
    elif (( $COLUMNS > 60 )); then
        echo "%*"
    fi
}

hg_prompt_info() {
    hg prompt --angle-brackets "${HG_PROMPT_BEFORE}<branch>< %{$fg_bold[red]%}<status> %{$fg_no_bold[yellow]%}>${HG_PROMPT_AFTER}" 2> /dev/null
}

HG_PROMPT_BEFORE="%{$fg_no_bold[white]%}%{$bg[white]%}%{$fg_no_bold[yellow]%} hg: "
HG_PROMPT_AFTER="%{$fg_no_bold[white]%}"

PROMPT='%{$bg[yellow]%}%{$fg_no_bold[white]%}%n@%m %{$reset_color%}%{$bg[cyan]%}%{$fg_no_bold[yellow]%}⮀ \
%{$fg_no_bold[white]%}%$(( $COLUMNS / 3 ))<..<${PWD/#$HOME/~} %{$reset_color%}%{$fg_no_bold[cyan]%}⮀ %{$reset_color%}'
RPROMPT='%(1j.%{$fg_no_bold[red]%}%{$bg[red]%}%{$fg[white]%} jobs: %{$fg_bold[white]%}%j%{$fg_no_bold[red]%}%{$bg[red]%}%{$fg[white]%}.)\
$(virtualenv_info)$(git_prompt_info)$(hg_prompt_info)%{${FG[024]}%}%{${BG[024]}%}%{$fg[white]%} $(show_time)%{$reset_color%}'

ZSH_THEME_TERM_TITLE_IDLE="%n@%m: %d"  # Prevent env vars appearing in title
ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%d%<<"

export VIRTUAL_ENV_DISABLE_PROMPT=true
