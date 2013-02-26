autoload -U colors && colors

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_no_bold[magenta]%}git%{$fg_no_bold[magenta]%}:(%{$fg_no_bold[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
#ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg_no_bold[red]%}✗%{$reset_color%}%{$fg_no_bold[magenta]%})"
#ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg_no_bold[green]%}✓%{$reset_color%}%{$fg_no_bold[magenta]%})"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg_no_bold[red]%}!%{$reset_color%}%{$fg_no_bold[magenta]%})"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_no_bold[magenta]%})"

virtualenv_info() {
    [ $VIRTUAL_ENV ] || return
    echo "$VENV_PROMPT_BEFORE$(basename $VIRTUAL_ENV)$VENV_PROMPT_AFTER"
}

VENV_PROMPT_BEFORE="%{$fg_no_bold[blue]%}venv:(%{$fg_no_bold[yellow]%}"
VENV_PROMPT_AFTER="%{$fg_no_bold[blue]%}) %{$reset_color%}"

show_time() {
    (( $COLUMNS > 80 )) || return
    date --rfc-3339=seconds 
}

hg_prompt_info() {
    hg prompt --angle-brackets "${HG_PROMPT_BEFORE}<branch>< <status>>${HG_PROMPT_AFTER}" 2> /dev/null
}

HG_PROMPT_BEFORE="%{$fg_no_bold[grey]%}hg:(%{$fg_no_bold[yellow]%}"
HG_PROMPT_AFTER="%{$fg_no_bold[grey]%}) %{$reset_color%}"

PROMPT='%{$fg_no_bold[yellow]%}%n%{$reset_color%}%{$fg_no_bold[yellow]%}@%m%{$reset_color%}%{$fg_no_bold[cyan]%}:%{$reset_color%}%{$fg_no_bold[cyan]%}%$(( $COLUMNS / 3 ))<..<${PWD/#$HOME/~}$ %{$reset_color%}'
RPROMPT='%(1j.%{$fg_no_bold[red]%}jobs:(%{$fg_no_bold[yellow]%}%j%{$fg_no_bold[red]%}) .)%{$reset_color%}$(virtualenv_info)%{$reset_color%}$(hg_prompt_info)$(git_prompt_info)%{$reset_color%}%{${FG[024]}%}$(show_time)%{$reset_color%}'

ZSH_THEME_TERM_TITLE_IDLE="%n@%m: %d"  # Prevent env vars appearing in title
ZSH_THEME_TERM_TAB_TITLE_IDLE="%15<..<%d%<<"

export VIRTUAL_ENV_DISABLE_PROMPT=true
