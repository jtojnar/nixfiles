{ pkgs, ... }:
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
}
