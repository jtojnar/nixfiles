{ ... }:

{
  environment.sessionVariables = rec {
    EDITOR = "nano";
    TERMINAL = "gnome-terminal";

    XDG_CACHE_HOME  = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME   = "$HOME/.local/share";

    CABAL_CONFIG = "${XDG_DATA_HOME}/cabal/config";
    CARGO_HOME = "${XDG_DATA_HOME}/cargo";
    NPM_CONFIG_USERCONFIG = "${XDG_CONFIG_HOME}/npm/npmrc";
  };
}
