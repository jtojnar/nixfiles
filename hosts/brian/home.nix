{ pkgs, ... }:

{
  home.packages = [
    pkgs.sublime4-dev
  ];

  programs.home-manager = {
    enable = true;
  };
}
