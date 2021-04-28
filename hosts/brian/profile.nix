{ inputs, pkgs, ... }:

let
  nixgl = import inputs.nixgl {
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

  # Custom utils
  git-part-pick
  git-auto-fixup
  git-auto-squash
  nix-explore-closure-size
  sman
]
