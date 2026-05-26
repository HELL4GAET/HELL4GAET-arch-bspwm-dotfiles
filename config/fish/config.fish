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

alias cls="clear"
alias g="git"
alias feh="feh --scale-down"

function fish_prompt
    set_color 61afef
    printf " "
    set_color c8ccd4
    printf "%s ~ " $USER
    set_color 989cff
    printf "❯ "
    set_color normal
end

if command -q bat
    alias cat="bat"
end

if command -q nvim
    alias n="nvim"
end
