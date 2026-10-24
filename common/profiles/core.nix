{ config, pkgs, ... }:
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

  services.xserver.xkb.dir =
    let
      xkb_patched = pkgs.xkeyboard-config.overrideAttrs (
        attrs: finalAttrs: {
          version = "2.49";
          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "xkeyboard-config";
            repo = "xkeyboard-config";
            tag = "xkeyboard-config-${finalAttrs.version}";
            hash = "sha256-55CigEgcPNc3YQlwFVKv+fV5W9JYwnsi9ZPgs13Z14w=";
          };
        }
      );
    in
    "${xkb_patched}/etc/X11/xkb";

  environment.sessionVariables = {
    # runtime override supported by multiple libraries e. g. libxkbcommon
    # https://xkbcommon.org/doc/current/group__include-path.html
    XKB_CONFIG_ROOT = config.services.xserver.xkb.dir;
  };
}
