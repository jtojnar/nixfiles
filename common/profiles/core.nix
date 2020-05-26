{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixFlakes;

    allowedUsers = [ "@wheel" ];

    trustedUsers = [ "root" "@wheel" ];

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  users.mutableUsers = false;
}
