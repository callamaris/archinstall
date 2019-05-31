
# if not running interactively, don't do anything
[[ $- != *i* ]] && return

# prompt
PS1='[\u@\h \W]\$'

# alias
alias ls='ls --color=auto'
alias cfg='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'


