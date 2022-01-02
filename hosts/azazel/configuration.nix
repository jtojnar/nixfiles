{ config, inputs, pkgs, ... }:

let
  keys = import ../../common/data/keys.nix;
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    "${inputs.nixpkgs}/nixos/modules/virtualisation/container-config.nix"
    ./vpsadminos.nix

    # sites
    ./fan-club-penguin.cz
    ./krk-litvinov.cz
    ./ogion.cz
    ./ostrov-tucnaku.cz
    ./rogaining.org
  ];

  environment.systemPackages = with pkgs; [
    fd
    file
    diff-so-fancy
    gitFull
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
    };

    nginx = {
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

      # Use mainline nginx instead of stable, and add some modules.
      package = pkgs.nginxMainline.override (orig: {
        modules = orig.modules ++ [
          pkgs.nginxModules.fancyindex
        ];
      });
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
    defaults.email = "acme@ogion.cz";
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

  system.stateVersion = "21.05";

  # The rest of the file is taken from:
  # https://github.com/vpsfreecz/vpsadminos/blob/bb71d18ef104796cbb559a8bda399b39eb24daec/os/lib/nixos-container/configuration.nix
  # Modulo the config copying as I will not be creating containers.
  systemd.extraConfig = ''
    DefaultTimeoutStartSec=900s
  '';

  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store in the Nix database.
    if [ -f /nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration &&
      rm /nix-path-registration
    fi
    # nixos-rebuild also requires a "system" profile
    ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
    # Add profiles to gcroots
    ln -sf /nix/var/nix/profiles /nix/var/nix/gcroots/profiles
  '';

  system.build.tarball = import "${inputs.nixpkgs}/nixos/lib/make-system-tarball.nix" {
    inherit (pkgs) stdenv closureInfo pixz;
    compressCommand = "gzip";
    compressionExtension = ".gz";
    extraInputs = [ pkgs.gzip ];

    contents = [];
    storeContents = [
      { object = config.system.build.toplevel + "/init";
        symlink = "/sbin/init";
      }
      { object = config.system.build.toplevel;
        symlink = "/run/current-system";
      }
    ];
    extraCommands = "mkdir -p boot proc sys dev etc";
  };
}
