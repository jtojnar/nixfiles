{ config, pkgs, lib, ... }:

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

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/53c65a34-aef8-4a68-9485-b4415b202e03"; # Obtained using `blkid /dev/sda2`
      preLVM = true;
      allowDiscards = true;
    };
  };

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
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  i18n = {
    defaultLocale = "en_GB.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  swapDevices = [
    {
      device = "/var/swap";
      size = 1024 * 8 * 2; # twice the RAM should leave enough space for hibernation
    }
  ];

  # Configure sound.
  hardware = {
    pulseaudio = {
      enable = true;
      extraModules = [
        pkgs.pulseaudio-modules-bt
      ];
      package = pkgs.pulseaudioFull;
      zeroconf = {
        discovery.enable = true;
        publish.enable = true;
      };
    };
    bluetooth.enable = true;

    cpu.intel.updateMicrocode = true;
  };

  environment.systemPackages = with pkgs; [
    abiword
    almanah
    anki
    apg
    bat
    bind
    binutils # readelf, xstrings
    bustle
    cawbird
    chromium
    common-updater-scripts
    curlFull
    (deadbeef-with-plugins.override {
      plugins = with deadbeefPlugins; [
        headerbar-gtk3
        lyricbar
        mpris2
      ];
    })
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
    fzf
    gcolor3
    gdb
    gimp
    gitAndTools.gh
    gitAndTools.diff-so-fancy
    gitAndTools.git-bz
    gitAndTools.gitFull
    gitg
    git-auto-fixup
    git-auto-squash
    git-part-pick
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
    gnumeric
    gnupg
    gsmartcontrol
    gtk3.dev # for gtk-builder-tool etc
    graphviz
    python3.pkgs.xdot
    htop
    imagemagick
    indent
    inkscape
    jq
    libxml2 # for xmllint
    lorri
    ltrace
    meld
    mkpasswd
    moreutils # isutf8
    mypaint
    ncdu
    nixpkgs-fmt
    nix-explore-closure-size
    onboard
    paprefs
    patchelf
    patchutils # for filterdiff
    playerctl
    posix_man_pages
    pulseeffects
    python3Full
    ripgrep
    sequeler
    sman
    sublime3-dev
    spotify
    tdesktop
    tldr
    transmission_gtk
    unrar
    valgrind
    vlc
    wget
    wirelesstools # for iwlist
    xsel
    xsv # handling CSV files
    youtube-dl
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

        set fish_greeting

        set -x EDITOR nano
        set -x TERMINAL gnome-terminal

        set -x QT_QPA_PLATFORMTHEME qt5ct

        set -x XDG_CONFIG_HOME $HOME/.config
        set -x XDG_DATA_HOME $HOME/.local/share
        set -x XDG_CACHE_HOME $HOME/.cache

        set -x CABAL_CONFIG $XDG_DATA_HOME/cabal/config
        set -x CARGO_HOME $XDG_DATA_HOME/cargo
        set -x CCACHE_DIR $XDG_CACHE_HOME/ccache
        set -x GNUPGHOME $XDG_DATA_HOME/gnupg
        set -x GTK2_RC_FILES $XDG_CONFIG_HOME/gtk-2.0/gtkrc
        set -x NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/config
        set -x NPM_CONFIG_CACHE $XDG_CACHE_HOME/npm
        set -x NPM_CONFIG_TMP $XDG_RUNTIME_DIR/npm
        set -x RUSTUP_HOME $XDG_DATA_HOME/rustup
        set -x STACK_ROOT $XDG_DATA_HOME/stack
        set -x RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/config
      '';
    };
    gnupg.agent.enable = true;
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
  services.xserver.displayManager.defaultSession = "gnome";


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

      [org.gnome.desktop.input-sources]
      sources=[('xkb', '${config.services.xserver.layout}${lib.optionalString (config.services.xserver.xkbVariant != "") "+" + config.services.xserver.xkbVariant}')]
      xkb-options=['${config.services.xserver.xkbOptions}']
    '';
  };

  # Ugly hack for GPG choosing socket directory based on GNUPGHOME.
  # If any other user wants to use gpg-agent they are out of luck,
  # unless they modify the socket in their profile (e.g. using home-manager).
  systemd.user.sockets.gpg-agent = {
    listenStreams = let
      user = "jtojnar";
      socketDir = pkgs.runCommand "gnupg-socketdir" {
        nativeBuildInputs = [ pkgs.python3 ];
      } ''
        python3 ${../../common/gnupgdir.py} '/home/${user}/.local/share/gnupg' > $out
      '';
    in [
      "" # unset
      "%t/gnupg/${builtins.readFile socketDir}/S.gpg-agent"
    ];
  };

  # Define a user account. Don’t forget to set a password with ‘passwd’.
  users.extraUsers = {
    root = {
      hashedPassword = "*";
    };

    jtojnar = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [ "wheel" "networkmanager" "wireshark" "docker" "vboxusers" ];
      useDefaultShell = true;
      openssh.authorizedKeys.keys = keys.jtojnar;
      passwordFile = "/etc/nixos/passwd/jtojnar";
    };
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
      (import ../../common/overlays/debugging)
      (import ../../common/pkgs)

      (self: super: {
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

    trustedUsers = [ "@wheel" ];

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
