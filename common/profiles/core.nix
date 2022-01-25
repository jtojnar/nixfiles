{ lib, pkgs, ... }:
{
  nix = {
    package = pkgs.nixUnstable;

    allowedUsers = [ "@wheel" ];

    trustedUsers = [ "root" "@wheel" ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Does not work without channels.
  programs.command-not-found.enable = false;

  users.mutableUsers = false;

  security.wrappers.pkexec.source =
    let
      freshPolkit = pkgs.polkit.overrideAttrs (attrs: {
        patches = attrs.patches or [ ] ++ [
          (pkgs.fetchpatch {
            url = "https://gitlab.freedesktop.org/polkit/polkit/-/commit/a2bf5c9c83b6ae46cbd5c779d3055bff81ded683.patch";
            sha256 = "162jkpg2myq0rb0s5k3nfr4pqwv9im13jf6vzj8p5l39nazg5i4s";
          })
        ];
      });
    in
    lib.mkForce "${freshPolkit.bin}/bin/pkexec";
}
