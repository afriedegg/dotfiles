autoload -U colors && colors

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_no_bold[magenta]%}git%{$fg_no_bold[magenta]%}:(%{$fg_no_bold[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_no_bold[magenta]%}) %{$fg_no_bold[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_no_bold[magenta]%}) %{$fg_no_bold[green]%}✔%{$reset_color%}"

function virtualenv_info {
    [ $VIRTUAL_ENV ] || return
    echo "$VENV_PROMPT_BEFORE$(basename $VIRTUAL_ENV)$VENV_PROMPT_AFTER"
}

VENV_PROMPT_BEFORE="%{$fg_no_bold[blue]%}venv%{$fg_no_bold[blue]%}:(%{$fg_no_bold[yellow]%}"
VENV_PROMPT_AFTER="%{$fg_no_bold[blue]%}) %{$reset_color%}"

PROMPT='%{$fg_no_bold[yellow]%}%n%{$reset_color%}%{$fg_no_bold[yellow]%}@%m%{$reset_color%}%{$fg_no_bold[cyan]%}:%{$reset_color%}%{$fg_no_bold[cyan]%}${PWD/#$HOME/~}$ %{$reset_color%}'
RPROMPT='$(virtualenv_info)%{$reset_color%}$(git_prompt_info) %{$reset_color%}'
