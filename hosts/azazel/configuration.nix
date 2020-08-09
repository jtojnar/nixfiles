{ config, inputs, pkgs, ... }:

let
  keys = import ../../common/data/keys.nix;
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
    "${inputs.nixpkgs}/nixos/modules/virtualisation/container-config.nix"
    ./build.nix
    ./networking.nix

    # sites
    ./fan-club-penguin.cz
    ./krk-litvinov.cz
    ./ogion.cz
    ./ostrov-tucnaku.cz
    ./rogaining.org
  ];

  environment.systemPackages = with pkgs; [
    file
    gitAndTools.diff-so-fancy
    gitAndTools.gitFull
    moreutils # isutf8
    ncdu
    ripgrep
    tldr
  ];

  # Prefer using cached builds over saving space.
  environment.noXlibs = false;

  programs = {
    fish.enable = true;
  };

  services = {
    mysql = {
      package = pkgs.mariadb;

      settings = {
        "mariadb" = {
          # TODO: remove after upgrading 10.4.3
          "unix_socket" = "ON";
          "plugin_load_add" = [
            "auth_socket"
          ];
        };
      };
    };

    openssh = {
      enable = true;
      passwordAuthentication = false;
    };

    phpfpm = rec {
      phpOptions = ''
        display_startup_errors = On
        display_errors = On
        log_errors = On
        upload_max_filesize = 20M
        memory_limit = 256M
        default_socket_timeout = 500
        max_execution_time = 500
        request_terminate_timeout = 500
        post_max_size = 20M
        error_reporting = E_ALL | E_STRICT
        date.timezone = "Europe/Prague"
      '';
    };

    postfix = {
      enable = true;
      domain = "mxproxy.ogion.cz";
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

      tojnar = {
        uid = 1001;
        isNormalUser = true;
        openssh.authorizedKeys.keys = keys.otec;
      };
    };

    defaultUserShell = pkgs.fish;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.fail2ban.enable = true;

  time.timeZone = "Europe/Prague";

  documentation.enable = true;
  documentation.nixos.enable = true;

  system.stateVersion = "18.09";
}
