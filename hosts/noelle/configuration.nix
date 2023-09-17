{ config, pkgs, ... }:

let
  keys = import ../../common/data/keys.nix;
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    firefox
    gitFull
    gnome.dconf-editor
    gnome.gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    htop
    libreoffice-fresh
    sublime-merge
    sublime4
    telegram-desktop
    vlc
    warp
  ];

  programs = {
    # Console interface
    fish = {
      enable = true;
      interactiveShellInit = ''
        eval (${pkgs.direnv}/bin/direnv hook fish)
      '';
    };

    # Clipboard manager
    gpaste.enable = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Select internationalisation properties.
  i18n.defaultLocale = "cs_CZ.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  home-manager.users.dtojnaro = { lib, ... }: {
    imports = [
      ../../common/configs/sublime
    ];

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        enable-hot-corners = false;
      };

      "org/gnome/desktop/screensaver" = {
        lock-delay = lib.hm.gvariant.mkUint32 3600;
        lock-enabled = true;
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        click-method = "default";
        natural-scroll = false;
        speed = lib.hm.gvariant.mkDouble 1.0;
        tap-to-click = true;
      };

      "org/gnome/desktop/session" = {
        idle-delay = lib.hm.gvariant.mkUint32 900;
      };

      "org/gnome/desktop/wm/keybindings" = {
        switch-windows = [ "<Alt>Tab" ];
        switch-windows-backward = [ "<Shift><Alt>Tab" ];
      };

      "org/gnome/shell/extensions/dash-to-dock" = {
        show-trash = false;
      };

      "org/gnome/mutter" = {
        dynamic-workspaces = true;
      };

      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "small";
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
            "${config.services.xserver.layout}${lib.optionalString (config.services.xserver.xkbVariant != "") "+" + config.services.xserver.xkbVariant}"
          ])
        ];
        xkb-options = [
          config.services.xserver.xkbOptions
        ];
      };
    };

    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    home.stateVersion = "22.11";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "cz";
    xkbVariant = "qwerty_bksl";
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
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
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };
  };

  services.tailscale.enable = true;

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

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;
    users = {
      # Disable direct admin login.
      root = {
        hashedPassword = "*";
        openssh.authorizedKeys.keys = keys.jtojnar;
      };

      dtojnaro = {
        isNormalUser = true;
        hashedPassword = "$y$j9T$y6dQ0q08yGif/mPAwERdj/$VCs//ibuvji1O26kZyUYdfniMEtwykodd9RsruNCmh/";
        description = "Dagmar Tojnarová";
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

  services.logind = {
    # Laptop sends false events when used in bed.
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
  };

  swapDevices = [
    {
      device = "/var/swap";
      size = 1024 * 4 * 2; # twice the RAM should leave enough space for hibernation
    }
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
