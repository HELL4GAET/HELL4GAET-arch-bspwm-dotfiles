set -U fish_greeting

set -g fish_color_autosuggestion 555 brblack
set -g fish_color_cancel -r
set -g fish_color_command green
set -g fish_color_comment red
set -g fish_color_cwd green
set -g fish_color_cwd_root red
set -g fish_color_end green
set -g fish_color_error brred
set -g fish_color_escape brcyan
set -g fish_color_history_current --bold
set -g fish_color_host normal
set -g fish_color_host_remote yellow
set -g fish_color_normal normal
set -g fish_color_operator brcyan
set -g fish_color_param cyan
set -g fish_color_quote yellow
set -g fish_color_redirection cyan --bold
set -g fish_color_search_match --background=111
set -g fish_color_selection white --bold --background=brblack
set -g fish_color_status red
set -g fish_color_user brgreen
set -g fish_color_valid_path --underline
set -g fish_pager_color_completion normal
set -g fish_pager_color_description B3A06D yellow -i
set -g fish_pager_color_prefix cyan --bold --underline
set -g fish_pager_color_progress brwhite --background=cyan
set -g fish_pager_color_selected_background -r

set -gx EDITOR code
set -gx VISUAL code
set -gx BROWSER /usr/bin/firefox
fish_add_path -g "$HOME/go/bin"

alias cls="clear"
alias g="git"
alias feh="feh --scale-down"
alias dstart="sudo systemctl start docker.socket docker.service"
alias dstop="sudo systemctl stop docker.service docker.socket"
alias dstatus="systemctl status docker.service docker.socket"

function fish_prompt
    set_color 61afef
    printf " "
    set_color normal
    printf "%s@%s " $USER (prompt_hostname)
    set_color $fish_color_cwd
    printf "%s" (prompt_pwd)
    set_color normal
    printf "> "
    set_color normal
end

if command -q bat
    alias cat="bat"
end

if command -q nvim
    alias n="nvim"
end
