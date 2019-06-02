
# if not running interactively, don't do anything
[[ $- != *i* ]] && return

# prompt
PS1='[\u@\h \W]\$'

# alias
[ -f "$HOME/.config/aliasrc" ] && source "$HOME/.config/aliasrc"

