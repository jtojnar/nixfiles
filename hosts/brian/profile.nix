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
  anki
  bat
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
  droidcam
  exa
  fd
  fzf
  gimp
  gnome3.geary
  gitAndTools.gh
  gitAndTools.git-crypt
  nixFlakes
  nixgl.nixGLIntel
  inkscape
  nix-du
  nix-direnv
  nix-index
  nix-review
  pandoc
  patchelf
  ripgrep
  source-code-pro
  spotify
  sublime-merge
  sublime4-dev
  tdesktop
  vlc
  youtube-dl
]
