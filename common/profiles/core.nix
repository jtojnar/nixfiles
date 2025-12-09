{ pkgs, ... }:
{
  nix = {
    settings = {
      allowed-users = [ "@wheel" ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  # Does not work without channels.
  programs.command-not-found.enable = false;

  users.mutableUsers = false;

  environment.etc."xdg/gnome-mimeapps.list".source =
    pkgs.runCommand "gnome-mimeapps-overridden.list" { }
      ''
        cp "${pkgs.gnome-session}/share/applications/gnome-mimeapps.list" "$out"

        # Use File Roller for all archives
        substituteInPlace "$out" \
          --replace-fail "org.gnome.Nautilus.desktop" 'org.gnome.FileRoller.desktop' \
          --replace-fail "inode/directory=org.gnome.FileRoller.desktop" 'inode/directory=org.gnome.Nautilus.desktop'
      '';
}
