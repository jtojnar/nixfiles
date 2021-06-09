{ pkgs, inputs, ... }:

let
  fonts = (inputs.self.nixosModules.profiles.fonts { inherit pkgs; }).fonts.fonts;
in

{
  imports = [
    ./dwarffs.nix
  ];

  home.packages = with pkgs; [
    anki-bin
    aw-qt
    aw-server-rust
    aw-watcher-afk
    aw-watcher-window
    bat
    cachix
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
    gdb
    gimp
    gnome.geary
    gh
    gitFull
    git-crypt
    nixUnstable
    nixgl.nixGLIntel
    inkscape
    nix-du
    nix-direnv
    nix-index
    nixpkgs-review
    pandoc
    patchelf
    pdftag
    playerctl
    ripgrep
    sd
    source-code-pro
    spotify
    sublime-merge
    sublime4-dev
    tdesktop
    vlc
    vscodium
    youtube-dl

    # Custom utils
    git-part-pick
    git-auto-fixup
    git-auto-squash
    nix-explore-closure-size
    sman
  ] ++ fonts;

  fonts.fontconfig.enable = true;

  programs.fish = {
    enable = true;

    interactiveShellInit = builtins.readFile ../../common/data/config.fish;

    functions = {
      mkcd = {
        description = "Create a directory then “cd” to it";
        body = ''
          #doc
          # `mkcd foo/bar/baz`: Runs `mkdir foo/bar/baz` then `cd foo/bar/baz`
          #enddoc

          mkdir -p "$argv[1]"
          cd "$argv[1]"
        '';
      };
    };
  };
}
