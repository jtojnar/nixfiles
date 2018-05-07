# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  extrapkgs = import <extrapkgs> {};
  unstable = import (builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz) { };
  firefoxOverlay = import ("${builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz}/firefox-overlay.nix");
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = [
    {
      name = "root";
      device = "/dev/disk/by-uuid/e1dbb444-15cd-4e82-beff-08dd0b9de34f"; # Obtained using `blkid /dev/sda2`
      preLVM = true;
      allowDiscards = true;
    }
    {
      name = "ManjaroRoot";
      device = "/dev/disk/by-uuid/1f5da579-7241-4ac6-b0bb-cf25f7083ba2"; # Obtained using `blkid /dev/sdb2`
      preLVM = true;
    }
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    # Note that inotify watches consume 1kB on 64-bit machines.
    "fs.inotify.max_user_watches" = 1048576; # default: 8192
    "fs.inotify.max_user_instances" = 1024; # default: 128
    "fs.inotify.max_queued_events" = 32768; # default: 16384
    "kernel.perf_event_paranoid" = 1; # for rr, default: 2
  };

  boot.cleanTmpDir = true;

  networking.hostName = "kaiser"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleUseXkbConfig = true;
    defaultLocale = "en_GB.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [
        mozc
      ];
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  systemd.coredump.enable = true;

  # Configure sound.
  hardware = {
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
      zeroconf = {
        discovery.enable = true;
        publish.enable = true;
      };
    };
    bluetooth.enable = true;
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    unstable.abiword
    latest.firefox-nightly-bin
    apg
    binutils # readelf, xstrings
    bind
    bustle
    unstable.blender
    common-updater-scripts
    unstable.chromium
    corebird
    deadbeef-with-plugins
    dfeet
    diffoscope
    dos2unix
    unstable.easytag
    exa
    exiftool
    fd
    file
    font-manager
    unstable.gimp
    gcolor3
    gitAndTools.diff-so-fancy
    gitAndTools.gitFull
    gitg
    glib.dev # for gsettings
    gnome3.geary
    gnome3.ghex
    gnome3.polari
    gnomeExtensions.dash-to-dock
    gnomeExtensions.topicons-plus
    gnomeExtensions.nohotcorner
    unstable.gnumeric
    gnupg
    htop
    extrapkgs.hamster-gtk
    imagemagick
    indent
    unstable.inkscape
    jq
    libxml2 # for xmllint
    ltrace
    meld
    mkpasswd
    moreutils # isutf8
    mypaint
    ncdu
    nix-repl
    onboard
    paprefs
    patchutils # for filterdiff
    python3Full
    ripgrep
    sublime3
    unstable.sqlitebrowser
    unstable.tdesktop
    tldr
    transmission_gtk
    unstable.vlc
    wget
    xsel
  ];

  environment.enableDebugInfo = true;

  fonts = {
    fonts = with pkgs; [
      cantarell_fonts
      cm_unicode
      crimson
      dejavu_fonts
      font-droid
      fira
      fira-mono
      gentium
      google-fonts
      input-fonts
      ipafont
      ipaexfont
      league-of-moveable-type
      libertine
      libre-baskerville
      libre-bodoni
      libre-caslon
      lmmath
      lmodern
      source-code-pro
      source-sans-pro
      source-serif-pro
      ubuntu_font_family
    ];
  };

  # List programs
  programs = {
    adb.enable = true;
    command-not-found.enable = true;
    fish = {
      enable = true;
    };
    wireshark = {
      enable = true;
      package = pkgs.wireshark-gtk;
    };
  };

  documentation = {
    man.enable = true;
  };

  # List services that you want to enable:

  services.fwupd.enable = true;
  programs.plotinus.enable = true;

  services.gnome3.gpaste.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 5900 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "cz";
  services.xserver.xkbVariant = "qwerty";
  services.xserver.xkbOptions = "compose:caps";

  # Enable the Desktop Environment.
  services.xserver.displayManager.gdm = {
    enable = true;
    debug = true;
  };

  services.xserver.desktopManager.gnome3 = {
    enable = true;
    extraGSettingsOverridePackages = with pkgs; [ gnome3.nautilus gnome3.gnome_settings_daemon gtk3 ];
    extraGSettingsOverrides = ''
      [org.gnome.desktop.background]
      primary-color='#000000'
      secondary-color='#000000'
      picture-uri='file://${pkgs.reflection_by_yuumei}'

      [org.gnome.desktop.screensaver]
      lock-delay=3600
      lock-enabled=true
      picture-uri='file://${pkgs.undersea_city_by_mrainbowwj}'
      primary-color='#000000'
      secondary-color='#000000'

      [org.gnome.desktop.session]
      idle-delay=900

      [org.gnome.desktop.wm.keybindings]
      switch-input-source-backward=@as []
      switch-input-source=[]

      [org.gnome.settings-daemon.plugins.power]
      power-button-action='nothing'
      idle-dim=true
      sleep-inactive-battery-type='nothing'
      sleep-inactive-ac-timeout=3600
      sleep-inactive-ac-type='nothing'
      sleep-inactive-battery-timeout=1800

      [org.gnome.settings-daemon.plugins.media-keys]
      previous='<Super>b'
      custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']
      next='<Super>n'
      home='<Super>e'
      play='<Super>space'

      [org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0]
      binding='<Super>t'
      command='gnome-terminal'
      name='Open terminal'

      [org.gnome.desktop.peripherals.touchpad]
      click-method='default'

      [org.gnome.nautilus.preferences]
      automatic-decompression=false
      sort-directories-first=true

      [org.gtk.settings.file-chooser]
      sort-directories-first=true
      location-mode='path-bar'
    '';

  };

  environment.gnome3.excludePackages = with pkgs.gnome3; [
    evolution
    epiphany
    gnome-calendar
    gnome-documents
    gnome-maps
    gnome-music
    gnome-photos
    totem
  ];


  # Define a user account. Don’t forget to set a password with ‘passwd’.
  users.extraUsers.jtojnar = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "wireshark" "docker" ];
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDYbOlZydfRRCGCT08wdtPcpfSrgxMc6weDx3NcWrnMpVgxnMs3HozzkaS/hbcZUocn7XbCOyaxEd1O8Fuaw4JXpUBcMetpPXkQC+bZHQ3YsZZyzVgCXFPRF88QQj0nR7YVE1AeAifjk3TCODstTxit868V1639/TVIi5y5fC0/VbYG2Lt4AadNH67bRv8YiO3iTsHQoZPKD1nxA7yANHCuw38bGTHRhsxeVD+72ThbsYSZeA9dBrzACpEdnwyXclaoyIOnKdN224tu4+4ytgH/vH/uoUfL8SmzzIDvwZ4Ba2yHhZHs5iwsVjTvLe7jjE6I1u8qY7X8ofnanfNcsmz/ jtojnar@kaiser"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNxXH1FOY0Mr0c43ailpNUgZKmjqj7A53orVpeH0wLevX6fJbKkCbN6WhIz7HoNuS1sAsmnSfeAd8oOHQvJRmTDGiwtXInls5wht4QSKUmvcXta1XsToSquZRM3XQSBJj7qaPE6zGkT0WSQUkLllL+hMGpmPF+M/HcifmP4CitmsWXvG/LaPpZ5LQkq4sNkp1keC2rHz/WqLHineb6BRenr1kyP9KH/ZqW9uwmliVi5dJzOEWvcGErO/i52QlKa7hX2QGYwb//oFQiRkXQoyMSbDjSikyQbtX8uXeEa8tFbaZLHa359GeV0j0CEkDBMi5NEvMB7gpamjENT0gGSWwR jtojnar@gmail.com"
    ];
    passwordFile = "/etc/nixos/passwd/jtojnar";
  };

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "unstable";
  system.autoUpgrade.channel = https://nixos.org/channels/nixos-unstable;
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      firefoxOverlay

      (self: super: {
        deadbeef-with-plugins = super.deadbeef-with-plugins.override {
          plugins = with super.deadbeefPlugins; [ mpris2 opus ];
        };

        reflection_by_yuumei = super.fetchurl {
          url = "https://orig00.deviantart.net/0054/f/2015/129/b/9/reflection_by_yuumei-d8sqdu2.jpg";
          sha256 = "0f0vlmdj5wcsn20qg79ir5cmpmz5pysypw6a711dbaz2r9x1c79l";
        };

        undersea_city_by_mrainbowwj = super.fetchurl {
          url = "https://orig00.deviantart.net/5d0b/f/2015/270/2/5/undersea_city_by_mrainbowwj-d9b21c7.jpg";
          sha256 = "1rhsbirhfv865if3w6pxd3p4g158rjar1zinm7wpd7y4gc45yh5y";
        };
      })
    ];
  };

}
