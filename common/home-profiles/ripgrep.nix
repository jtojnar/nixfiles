{ pkgs, ... }:

{
  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.ripgrep.enable
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--hyperlink-format=rg-subl://{path}:{line}:{column}"
      "--type-add=patch:*.{patch,diff}"
      "--type-add=cocci:*.cocci"
    ];
  };

  home.packages = [
    (pkgs.makeDesktopItem {
      name = "rg-subl";
      desktopName = "Hyperlink handler for ripgrep";
      exec =
        let
          handler = pkgs.writeShellScript "rg-subl" ''
            declare -a a=()
            for f in "$@"; do
                a+=(''${f#rg-subl://})
            done
            exec subl "''${a[@]}"
          '';
        in
        "${handler} -- %U";
      mimeTypes = [
        "x-scheme-handler/rg-subl"
      ];
      noDisplay = true;
    })
  ];
}
