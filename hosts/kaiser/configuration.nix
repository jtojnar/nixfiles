{ config, pkgs, ... }:

let
  keys = import ../../keys.nix;
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./development/web.nix
  ];

  boot.supportedFilesystems = [ "ntfs" ];

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
  boot.kernelParams = [
    "boot.shell_on_fail"
  ];

  boot.kernel.sysctl = {
    # Note that inotify watches consume 1kB on 64-bit machines.
    "fs.inotify.max_user_watches" = 1048576; # default: 8192
    "fs.inotify.max_user_instances" = 1024; # default: 128
    "fs.inotify.max_queued_events" = 32768; # default: 16384
    "kernel.perf_event_paranoid" = 1; # for rr, default: 2
    "kernel.sysrq" = 1; # allow all magic SysRq keys
  };

  boot.cleanTmpDir = true;

  networking.hostName = "kaiser"; # Define your hostname.

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleUseXkbConfig = true;
    defaultLocale = "en_GB.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  swapDevices = [
    {
      device = "/var/swap";
    }
  ];

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

  environment.systemPackages = with pkgs; [
    abiword
    almanah
    apg
    bat
    bind
    binutils # readelf, xstrings
    blueman
    bustle
    cawbird
    chromium
    common-updater-scripts
    deadbeef-with-plugins
    deja-dup
    dfeet
    diffoscope
    direnv
    dos2unix
    easytag
    exa
    exiftool
    fd
    file
    firefox
    font-manager
    fractal
    gcolor3
    gdb
    gimp
    gitAndTools.diff-so-fancy
    gitAndTools.git-bz
    gitAndTools.git-hub
    gitAndTools.gitFull
    gitg
    gnome-mpv
    gnome3.cheese
    gnome3.dconf-editor
    gnome3.devhelp
    gnome3.geary
    gnome3.ghex
    gnome3.glade
    gnome3.gnome-chess
    gnome3.gnome-dictionary
    gnome3.gnome-disk-utility
    gnome3.gnome-tweaks
    gnome3.polari
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.gsconnect
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.window-corner-preview
    gnumeric
    gnupg
    gsmartcontrol
    gtk3.dev # for gtk-builder-tool etc
    htop
    imagemagick
    indent
    inkscape
    jq
    libxml2 # for xmllint
    ltrace
    meld
    mkpasswd
    moreutils # isutf8
    mypaint
    ncdu
    onboard
    p7zip
    paprefs
    patchelf
    patchutils # for filterdiff
    posix_man_pages
    pulseeffects
    python3Full
    ripgrep
    sequeler
    sublime3-dev
    tdesktop
    tldr
    transmission_gtk
    unrar
    valgrind
    wget
    wirelesstools # for iwlist
    xsel
    xsv # handling CSV files
  ];

  environment.enableDebugInfo = true;

  fonts = {
    fonts = with pkgs; [
      cantarell-fonts
      caladea # Cambria replacement
      carlito # Calibri replacement
      comic-relief # Comic Sans replacement
      cm_unicode
      crimson
      dejavu_fonts
      fira
      fira-mono
      gentium
      google-fonts
      input-fonts
      ipafont
      ipaexfont
      league-of-moveable-type
      libertine
      noto-fonts-emoji
      joypixels
      liberation_ttf_v2 # Arial, Times New Roman & Courier New replacement
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

  fonts.fontconfig.defaultFonts.emoji = [ "JoyPixels" ];

  # List programs
  programs = {
    adb.enable = true;
    command-not-found.enable = true;
    fish = {
      enable = true;
      interactiveShellInit = ''
        eval (${pkgs.direnv}/bin/direnv hook fish)
      '';
    };
    wireshark.enable = true;
  };

  documentation = {
    dev.enable = true;
  };

  # List services that you want to enable:

  services.flatpak.enable = true;
  services.pipewire.enable = true;
  services.acpid = {
    enable = true;
    handlers = {
      mute = {
        event = "button/fnf1";
        action = ''
          device=/sys/devices/platform/sony-laptop/touchpad
          expr 1 - $(cat $device) > $device
        '';
      };
    };
  };

  boot.plymouth.enable = true;
  services.sysprof.enable = true;
  services.fwupd.enable = true;

  programs.gpaste.enable = true;

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
    extraGSettingsOverridePackages = with pkgs; [ gnome3.nautilus gnome3.gnome-settings-daemon gtk3 ];
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

  # Define a user account. Don’t forget to set a password with ‘passwd’.
  users.extraUsers.jtojnar = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "wireshark" "docker" "vboxusers" ];
    useDefaultShell = true;
    openssh.authorizedKeys.keys = keys.jtojnar;
    passwordFile = "/etc/nixos/passwd/jtojnar";
  };

  users.defaultUserShell = pkgs.fish;
  users.mutableUsers = false;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "18.03";
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      (import ../../overlays/debugging.nix)

      (self: super: {
        deadbeef-with-plugins = super.deadbeef-with-plugins.override {
          plugins = with super.deadbeefPlugins; [ headerbar-gtk3 lyricbar mpris2 ];
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

  nix = {
    package = pkgs.nixUnstable;
    useSandbox = true;
    buildCores = 0;
    maxJobs = 8;

    nixPath = [
      "nixpkgs=/home/jtojnar/Projects/nixpkgs"
    ];

    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "aarch64.nixos.community";
        maxJobs = 64;
        sshKey = "/root/id_aarch64box";
        sshUser = "jtojnar";
        system = "aarch64-linux";
        supportedFeatures = [ "big-parallel" ];
      }
    ];
  };
}
