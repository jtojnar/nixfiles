{ pkgs, ... }:
{
  nix = {
    settings = {
      auto-allocate-uids = true;
      allowed-users = [ "@wheel" ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      experimental-features = [
        "auto-allocate-uids"
        "cgroups"
        "nix-command"
        "flakes"
      ];
      extra-system-features = [
        "uid-range"
      ];
      use-xdg-base-directories = true;
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

  security.pki.caCertificateBlacklist = [
    # CVE-2026-111943
    "Comodo AAA Services root"
    # https://hg-edge.mozilla.org/projects/nss/rev/26d38a0c3fb81e7fb2acedbaf4c42dd21dce0517
    "emSign ECC Root CA - G3"
    # https://hg-edge.mozilla.org/projects/nss/rev/8159223c48ceeb1273a1915bca95a517294ab0e0
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];
}
