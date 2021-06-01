set fish_greeting

set -x EDITOR nano
set -x TERMINAL gnome-terminal

set -x QT_QPA_PLATFORMTHEME qt5ct

set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_DATA_HOME $HOME/.local/share
set -x XDG_CACHE_HOME $HOME/.cache

set -x ATOM_HOME $XDG_DATA_HOME/atom
set -x CABAL_CONFIG $XDG_DATA_HOME/cabal/config
set -x CARGO_HOME $XDG_DATA_HOME/cargo
set -x CCACHE_DIR $XDG_CACHE_HOME/ccache
set -x GNUPGHOME $XDG_CONFIG_HOME/gnupg
set -x GTK2_RC_FILES $XDG_CONFIG_HOME/gtk-2.0/gtkrc
set -x NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/config
set -x NPM_CONFIG_CACHE $XDG_CACHE_HOME/npm
set -x NPM_CONFIG_TMP $XDG_RUNTIME_DIR/npm
set -x RUSTUP_HOME $XDG_DATA_HOME/rustup
set -x STACK_ROOT $XDG_DATA_HOME/stack
set -x WEECHAT_HOME $XDG_CONFIG_HOME/weechat
set -x XAUTHORITY $XDG_RUNTIME_DIR/Xauthority
set -x XCOMPOSEFILE $XDG_CONFIG_HOME/x11/xcompose
set -x RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/config

set PATH $PATH $CARGO_HOME/bin $HOME/.local/bin

alias clip "xsel --clipboard"
alias reset "tput reset"
alias diff-cleaner "filterdiff --strip=0 --clean"
