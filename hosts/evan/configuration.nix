{ config, pkgs, ... }:

let
  keys = import ../../common/data/keys.nix;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    file-roller
    gitFull
    vlc
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnome-tweaks
    warp
    telegram-desktop
  ];

  programs = {
    # Console interface
    fish = {
      enable = true;
      interactiveShellInit = ''
        eval (${pkgs.direnv}/bin/direnv hook fish)
      '';
    };

    firefox = {
      enable = true;
    };

    # Mobile phone integration
    kdeconnect = {
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };

    # Clipboard manager
    gpaste.enable = true;

    steam.enable = true;
  };

  # App store.
  services.flatpak.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT = "cs_CZ.UTF-8";
    LC_MONETARY = "cs_CZ.UTF-8";
    LC_NAME = "cs_CZ.UTF-8";
    LC_NUMERIC = "cs_CZ.UTF-8";
    LC_PAPER = "cs_CZ.UTF-8";
    LC_TELEPHONE = "cs_CZ.UTF-8";
    LC_TIME = "cs_CZ.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  home-manager.users.michal =
    { lib, ... }:
    {
      dconf.settings = {
        "org/gnome/desktop/screensaver" = {
          lock-delay = lib.hm.gvariant.mkUint32 3600;
          lock-enabled = true;
        };

        "org/gnome/desktop/peripherals/touchpad" = {
          click-method = "default";
          tap-to-click = true;
        };

        "org/gnome/desktop/session" = {
          idle-delay = lib.hm.gvariant.mkUint32 900;
        };

        "org/gnome/settings-daemon/plugins/power" = {
          power-button-action = "nothing";
          idle-dim = true;
          sleep-inactive-battery-type = "nothing";
          sleep-inactive-ac-timeout = 3600;
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-timeout = 1800;
        };

        "org/gnome/shell" = {
          "enabled-extensions" = [
            "appindicatorsupport@rgcjonas.gmail.com"
            "dash-to-dock@micxgx.gmail.com"
            "GPaste@gnome-shell-extensions.gnome.org"
          ];
        };

        "org/gtk/settings/file-chooser" = {
          sort-directories-first = true;
          location-mode = "path-bar";
        };

        "org/gtk/gtk4/settings/file-chooser" = {
          sort-directories-first = true;
        };

        "org/gnome/desktop/input-sources" = {
          sources = [
            (lib.hm.gvariant.mkTuple [
              "xkb"
              "${config.services.xserver.xkb.layout}${
                lib.optionalString (config.services.xserver.xkb.variant != "") "+"
                + config.services.xserver.xkb.variant
              }"
            ])
          ];
          xkb-options = [
            config.services.xserver.xkb.options
          ];
        };
      };

      programs = {
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };

      home.stateVersion = "24.05";
    };

  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 42000;
        to = 42001;
      }
    ];
  };

  services.xserver = {
    # Configure keymap in X11
    xkb = {
      layout = "cz";
      variant = "qwerty";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        # Battery API does not have a separate UUID.
        Experimental = "*";
      };
    };
  };
  security.rtkit.enable = true;

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };
  };

  services.tailscale.enable = true;

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;
    users = {
      # Disable direct admin login.
      root = {
        hashedPassword = "*";
        openssh.authorizedKeys.keys = keys.jtojnar;
      };

      michal = {
        isNormalUser = true;
        hashedPassword = "$6$jLkpKiUzIxLySPl.$ABTo/BTFQseqvId84IWM3zBRL2TKYxfBo.rjrx3zbcj1gJo3j1/G4TzCF/8xk3.MOSl4FJRvXCe20wHFUQpjS/";
        description = "Michal";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        useDefaultShell = true;
      };
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable networking
  networking.networkmanager.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
