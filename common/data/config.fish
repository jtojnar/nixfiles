set fish_greeting

set -x EDITOR nano
set -x TERMINAL gnome-terminal

set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share
set -x XDG_CACHE_HOME $HOME/.cache

set -x CABAL_CONFIG $XDG_DATA_HOME/cabal/config
set -x CARGO_HOME $XDG_DATA_HOME/cargo
set -x GNUPGHOME $XDG_DATA_HOME/gnupg
set -x NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc
set -x RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/config

alias clip "xsel --clipboard"
alias reset "tput reset"
alias diff-cleaner "filterdiff --strip=0 --clean"
