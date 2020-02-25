{ config, pkgs, ... }:

let
  keys = import ../../keys.nix;
in {
  imports = [
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    <nixpkgs/nixos/modules/virtualisation/container-config.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ./build.nix
    ./networking.nix

    # sites
    ./ogion.cz
    ./rogaining.org
  ];

  environment.systemPackages = with pkgs; [
    vim
  ];

  programs = {
    fish.enable = true;
  };

  services = {
    openssh = {
      enable = true;
      passwordAuthentication = false;
    };
  };

  security.acme = {
    email = "acme@ogion.cz";
    acceptTerms = true;
  };

  users = {
    users = {
      root = {
        openssh.authorizedKeys.keys = keys.jtojnar;
        hashedPassword = "*";
      };
      jtojnar = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = keys.jtojnar;
        hashedPassword = "$6$yqXBTritxLsTNhy.$baY8JEagVyeBmpV6WCLY7nH4YH6YAjWiBPAvgF0zcVjYr7yagBmpZtmX/EFMedgxbCnU7l97SdG7EV6yfT.In/";
      };
    };

    defaultUserShell = pkgs.fish;
    mutableUsers = false;
  };

  networking.hostName = "azazel";

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  time.timeZone = "Europe/Prague";

  documentation.enable = true;
  documentation.nixos.enable = true;

  system.stateVersion = "18.09";
}
