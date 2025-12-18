{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  keys = import ../../common/data/keys.nix;
in
{
  # Pass extra arguments to all modules.
  _module.args = {
    myLib = import ./lib.nix {
      inherit lib config pkgs;
    };
  };

  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    "${inputs.nixpkgs}/nixos/modules/virtualisation/container-config.nix"
    inputs.vpsadminos.nixosConfigurations.containerUnstable
    ./security/anubis.nix
    ./security/fail2ban.nix

    # sites
    ./fan-club-penguin.cz
    ./krk-litvinov.cz
    ./mala-zahradka-pro-radost.cz
    ./ogion.cz
    ./ostrov-tucnaku.cz
    ./rogaining.org
    ./tojnar.cz
  ];

  environment.systemPackages = with pkgs; [
    bat
    eza
    fd
    file
    htop
    diff-so-fancy
    gitFull
    git-lfs
    links2
    moreutils # isutf8
    ncdu
    ripgrep
    sd
    sqlite-interactive
    tldr
    unison
  ];

  programs = {
    fish = {
      enable = true;
      interactiveShellInit = builtins.readFile ../../common/data/config.fish;
    };
  };

  services = {
    mysql = {
      package = pkgs.mariadb_1011;
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
      settings = {
        PasswordAuthentication = false;

        # Try to reduce the chance of DOS from unauthenticated connections.
        LoginGraceTime = 20;
        MaxAuthTries = 3;
      };
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
      settings = {
        main = {
          mydomain = "mxproxy.ogion.cz";
          myorigin = "$mydomain";
        };
      };
    };
  };

  security.acme = {
    defaults.email = "acme@ogion.cz";
    acceptTerms = true;
  };

  security.polkit.enable = true;

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
        authelia.hashedPassword = "$argon2id$v=19$m=2097152,t=1,p=4$iOpm/qebAoaWn/HPsLOlsw$Zqk8LiHzqobnDEx2k8wK+K1vcu/l7X51LIJv5xhloiA";
        hashedPassword = "$6$ix1CRwqg9ZHsG1qx$T4O/ZaPjO5lycwdP3pzmraaMrIG9Cbqb2ny9a.CiKubse20CNjXbux/tBw58Al4g/W9VuGqJUH211UTwoyR4n0";
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

  time.timeZone = "Europe/Prague";

  documentation.enable = true;
  documentation.nixos.enable = true;

  nix = {
    settings = {
      substituters = [
        "https://cache.iog.io"
      ];
      trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      ];
    };
  };

  system.stateVersion = "24.05";

  # The rest of the file is taken from:
  # https://github.com/vpsfreecz/vpsadminos/blob/cc51709270dd3cfc50c0124f6e1055184320c552/os/lib/nixos-container/configuration.nix
  # Modulo the config copying as I will not be creating containers.
  systemd.settings.Manager = {
    DefaultTimeoutStartSec = "900s";
  };

  boot.postBootCommands = ''
    # After booting, register the contents of the Nix store in the Nix database.
    if [ -f /nix/nix-path-registration ]; then
      ${config.nix.package.out}/bin/nix-store --load-db < /nix/nix-path-registration &&
      rm /nix/nix-path-registration
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

    contents = [ ];
    storeContents = [
      {
        object = config.system.build.toplevel;
        symlink = "/run/current-system";
      }
    ];
    extraCommands = pkgs.writeScript "extra-commands.sh" ''
      mkdir -p boot dev etc proc sbin sys
      ln -s ${config.system.build.toplevel}/init sbin/init
    '';
  };
}
