let
  flake = import ../..;

  pkgs = import flake.inputs.nixpkgs {
    system = builtins.currentSystem;
    overlays = builtins.attrValues flake.overlays;
    config = { allowUnfree = true; };
  };
in with pkgs; [
  common-updater-scripts
  deadbeef
  exa
  fd
  gitAndTools.gh
  nixFlakes
  nix-du
  nix-index
  nix-review
  ripgrep
  sublime-merge
  sublime4-dev
  vlc
]
