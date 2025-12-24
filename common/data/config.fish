set fish_greeting

alias reset "tput reset"
alias diff-cleaner "filterdiff --strip=0 --clean"

# Restore previous key bindings
# https://github.com/fish-shell/fish-shell/issues/10926
bind alt-left prevd-or-backward-word
bind alt-right nextd-or-forward-word
bind alt-backspace backward-kill-word
bind alt-delete kill-word
bind ctrl-left backward-token
bind ctrl-right forward-token
bind ctrl-backspace backward-kill-token
# fish actually thinks I press ctrl-h when I press ctrl-backpace
bind ctrl-h backward-kill-token
bind ctrl-delete kill-token
