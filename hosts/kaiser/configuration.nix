# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  extrapkgs = import <extrapkgs> {};
  mozilla = import <mozilla> { inherit pkgs; };
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

  boot.kernel.sysctl = {
    # Note that inotify watches consume 1kB on 64-bit machines.
    "fs.inotify.max_user_watches"   = 1048576;   # default:  8192
    "fs.inotify.max_user_instances" =    1024;   # default:   128
    "fs.inotify.max_queued_events"  =   32768;   # default: 16384
  };

  networking.hostName = "kaiser"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleUseXkbConfig = true;
    defaultLocale = "en_GB.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

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
    abiword
    apg
    atom
    blender
    corebird
    deadbeef-with-plugins
    deadbeef-mpris2-plugin
    dos2unix
    exa
    file
    gimp
    gitAndTools.diff-so-fancy
    gitAndTools.gitFull
    gitg
    gnome3.ghex
    gnome3.polari
    gnomeExtensions.dash-to-dock
    gnumeric
    gnupg
    htop
    extrapkgs.hamster-gtk
    inkscape
    jq
    libxml2 # for xmllint
    ltrace
    meld
    mkpasswd
    mozilla.firefox-nightly-bin
    mypaint
    ncdu
    nix-repl
    pinentry_gnome
    psmisc
    python27Packages.syncthing-gtk
    ripgrep
    sublime3
    tdesktop
    transmission_gtk
    vlc
    wget
    xsel
  ];

  fonts = {
    fonts = with pkgs; [
      cantarell_fonts
      cm_unicode
      crimson
      dejavu_fonts
      font-droid
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
      noto-fonts
      noto-fonts-cjk
      opensans-ttf
      roboto
      source-code-pro
      source-sans-pro
      source-serif-pro
      fira
      fira-mono
    ];
  };

  # List programs
  programs = {
    command-not-found.enable = true;
    fish = {
      enable = true;
    };
    wireshark = {
      enable = true;
      package = pkgs.wireshark-gtk;
    };
  };

  # List services that you want to enable:

  services.dbus.packages = [ pkgs.gnome3.gconf ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
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
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome3 = {
    enable = true;
    # extraGSettingsOverrides = """

    # """;
  };

  services.gnome3.at-spi2-core.enable = true;

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


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.jtojnar = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" ];
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
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: with pkgs; {
      deadbeef-with-plugins = deadbeef-with-plugins.override {
        plugins = [ deadbeef-mpris2-plugin ];
      };
      gnupg = gnupg.override {
        pinentry = pinentry_gnome;
      };
    };
  };

}
