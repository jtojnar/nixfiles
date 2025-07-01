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
                f=''${f#rg-subl://}
                # Unescaping by Robin A. Meade
                # https://stackoverflow.com/a/70560850
                : "''${f//+/ }"; printf -v f '%b' "''${_//%/\\x}"
                a+=("$f")
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
