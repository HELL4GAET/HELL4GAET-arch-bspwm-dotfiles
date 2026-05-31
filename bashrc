#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias dstart='sudo systemctl start docker.socket docker.service'
alias dstop='sudo systemctl stop docker.service docker.socket'
alias dstatus='systemctl status docker.service docker.socket'
export PATH="$HOME/go/bin:$PATH"
PS1='[\u@\h \W]\$ '
