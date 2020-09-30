let
  flake = import ../..;

  pkgs = import flake.inputs.nixpkgs {
    system = builtins.currentSystem;
    overlays = builtins.attrValues flake.overlays;
    config = { allowUnfree = true; };
  };

  nixgl = import flake.inputs.nixgl {
    inherit pkgs;
  };
in with pkgs; [
  common-updater-scripts
  chromium
  (deadbeef-with-plugins.override {
    plugins = with deadbeefPlugins; [
      headerbar-gtk3
      lyricbar
      mpris2
    ];
  })
  direnv
  exa
  fd
  gimp
  gitAndTools.gh
  nixFlakes
  nixgl.nixGLIntel
  inkscape
  nix-du
  nix-index
  nix-review
  patchelf
  ripgrep
  source-code-pro
  spotify
  sublime-merge
  sublime4-dev
  tdesktop
  vlc
]
