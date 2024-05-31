{ pkgs, ... }:

{
  # Single last selection not available on Package Control.
  # https://github.com/dperdikopoulos/Single-Last-Selection
  home.file.".config/sublime-text/Packages/User/single-last-selection.py".source = pkgs.fetchurl {
    url = "https://github.com/dperdikopoulos/Single-Last-Selection/raw/f1431e6ea693c6c785ad924e21b472e73a73b2e9/single-last-selection.py";
    hash = "sha256-P2yU9hVq8epaa7F0gzFg6uzzZCLg3qskwN/qYjhwR64=";
  };

  home.file.".config/sublime-text/Packages/Declaratives".source = ./Declarative;
}
