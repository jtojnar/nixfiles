{ pkgs, ... }:
{
  nix = {
    package = pkgs.nixUnstable;

    settings = {
      allowed-users = [ "@wheel" ];
      trusted-users = [ "root" "@wheel" ];
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  # Does not work without channels.
  programs.command-not-found.enable = false;

  users.mutableUsers = false;
}
