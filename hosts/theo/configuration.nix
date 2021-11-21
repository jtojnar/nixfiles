{ config, inputs, pkgs, lib, ... }:

let
  keys = import ../../common/data/keys.nix;

  userData = import ../../common/data/users.nix;

  dwarffsModule =
    { pkgs, ... }@args:
    let
      originalModule = inputs.dwarffs.nixosModules.dwarffs args;
    in
      originalModule // {
        # Overlay is already added when creating our pkgs (and with the correct Nix).
        nixpkgs = builtins.removeAttrs originalModule.nixpkgs [ "overlays" ];
      };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    dwarffsModule
    inputs.self.nixosModules.profiles.virt
    inputs.self.nixosModules.profiles.fonts
    ./development/web.nix
    ../../common/cachix.nix
  ];

  boot.supportedFilesystems = [ "ntfs" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/cdfe8ed6-90bf-4b26-a1d3-0f0efa267c58"; # Obtained using `blkid /dev/sda2`
      preLVM = true;
      allowDiscards = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "boot.shell_on_fail"
    # https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Hibernation
    "resume_offset=1736704" # physical offset of the first ext in `filefrag -v /var/swap`

    # The passive default severely degrades performance.
    "intel_pstate=active"
  ];

  boot.resumeDevice = "/dev/mapper/verbatim--20--vg-root";

  # Sony Vaio keyboard not working after suspend
  # https://discourse.nixos.org/t/keyboard-touchpad-do-not-wake-after-closing-laptop-lid/7565/6
  powerManagement.resumeCommands = "${pkgs.kmod}/bin/rmmod atkbd; ${pkgs.kmod}/bin/modprobe atkbd reset=1";

  boot.kernel.sysctl = {
    # Note that inotify watches consume 1kB on 64-bit machines.
    "fs.inotify.max_user_watches" = 1048576; # default: 8192
    "fs.inotify.max_user_instances" = 1024; # default: 128
    "fs.inotify.max_queued_events" = 32768; # default: 16384
    "kernel.perf_event_paranoid" = 1; # for rr, default: 2
    "kernel.sysrq" = 1; # allow all magic SysRq keys
  };

  systemd.tmpfiles.rules = [
    # 12G (RAM size) for hibernation image size
    # https://bbs.archlinux.org/viewtopic.php?pid=1731292#p1731292
    "w /sys/power/image_size - - - - ${toString (12*1024*1024*1024)}"
  ];

  boot.cleanTmpDir = true;

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
    pulseaudio.enable = false; # Using PipeWire
    bluetooth.enable = true;

    cpu.intel.updateMicrocode = true;
  };

  environment.systemPackages = with pkgs; [
    abiword
    almanah
    anki-bin
    apg
    bat
    bind
    binutils # readelf, xstrings
    bpb
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
    nix-direnv
    dos2unix
    easyeffects
    easytag
    exa
    exiftool
    fd
    file
    (firefox-wayland.override (args: args // {
      cfg = args.cfg or {} // {
        enableGnomeExtensions = true;
      };
    }))
    font-manager
    fractal
    fzf
    gcolor3
    gdb
    gimp
    diff-so-fancy
    git-bz
    git-crypt
    gitFull
    gitg
    git-auto-fixup
    git-auto-squash
    git-part-pick
    glade
    gnome.cheese
    gnome.dconf-editor
    gnome.devhelp
    gnome.geary
    gnome.ghex
    gnome.gnome-chess
    gnome.gnome-dictionary
    gnome.gnome-disk-utility
    gnome.gnome-tweaks
    gnome.nautilus-python
    gnome.polari
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.hot-edge
    gnomeExtensions.sound-output-device-chooser
    gnomeExtensions.system-monitor
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
    nix-index
    onboard
    paprefs
    pavucontrol
    patchelf
    patchutils # for filterdiff
    playerctl
    man-pages-posix
    python3Full
    ripgrep
    sequeler
    sman
    sublime4-dev
    sublime-merge
    spotify
    syncthing
    tdesktop
    tldr
    transmission-gtk
    unrar
    valgrind
    vlc
    vscodium
    wget
    wirelesstools # for iwlist
    xsel
    xsv # handling CSV files
    youtube-dl
    zotero
  ];

  services.udev.packages = with pkgs; [
    # qmk-udev-rules
  ];

  services.udev.extraRules = ''
    # https://www.pjrc.com/teensy/00-teensy.rules
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_PORT_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789a]*", ENV{MTP_NO_PROBE}="1"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", MODE:="0666", RUN:="${pkgs.coreutils}/bin/stty -F /dev/%k raw -echo"
    KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", MODE:="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04*", MODE:="0666"
    KERNEL=="hidraw*", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="013*", MODE:="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="013*", MODE:="0666"
  '';

  environment.pathsToLink = [
    "/share/nix-direnv"
  ];

  environment.enableDebugInfo = true;

  fonts.fontconfig.defaultFonts.emoji = [ "JoyPixels" ];

  # List programs
  programs = {
    adb.enable = true;
    fish = {
      enable = true;
      interactiveShellInit =
        ''
          eval (${pkgs.direnv}/bin/direnv hook fish)
        ''
        + builtins.readFile ../../common/data/config.fish;
    };
    gnupg.agent.enable = true;

    kdeconnect = {
      enable = true;
      package = pkgs.gnomeExtensions.gsconnect;
    };

    wireshark.enable = true;
  };

  documentation = {
    dev.enable = true;
  };

  # List services that you want to enable:

  services.flatpak.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

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

  security.sudo.extraConfig = ''
    Defaults pwfeedback
    Defaults timestamp_timeout=25
  '';

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


  services.xserver.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverridePackages = with pkgs; [ gnome.nautilus gnome.gnome-settings-daemon gtk3 ];
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
      previous=['<Super>b']
      custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']
      next=['<Super>n']
      home=['<Super>e']
      play=['<Super>space']

      [org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0]
      binding='<Super>t'
      command='gnome-terminal'
      name='Open terminal'

      [org.gnome.desktop.peripherals.touchpad]
      click-method='default'

      [org.gtk.settings.file-chooser]
      sort-directories-first=true
      location-mode='path-bar'

      [org.gnome.desktop.input-sources]
      sources=[('xkb', '${config.services.xserver.layout}${lib.optionalString (config.services.xserver.xkbVariant != "") "+" + config.services.xserver.xkbVariant}')]
      xkb-options=['${config.services.xserver.xkbOptions}']
    '';
  };

  i18n.inputMethod.enabled = "ibus";
  i18n.inputMethod.ibus.engines = with pkgs.ibus-engines; [ mozc ];

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

  environment.etc = {
    "gitconfig".text = ''
      [user]
        name = ${userData.jtojnar.name}
        email = ${userData.jtojnar.email}
        signingkey = ${userData.jtojnar.gpg}

      [push]
        default = current
        followTags = true

      [pull]
        ff = only

      [core]
        eol = lf
        autocrlf = false
        pager = diff-so-fancy | less --tabs=4 -RFX
        # allow using markdown headings in commit messages
        commentChar = ";"

      [commit]
        gpgsign = true

      [gpg]
        program = bpb

      # colour scheme for diff-so-fancy & co.
      # https://github.com/so-fancy/diff-so-fancy#improved-colors-for-the-highlighted-bits
      [color]
        ui = true
      [color "diff-highlight"]
        oldNormal = red bold
        oldHighlight = red bold 52
        newNormal = green bold
        newHighlight = green bold 22
      [color "diff"]
        meta = 227
        frag = magenta bold
        commit = 227 bold
        old = red bold
        new = green bold
        whitespace = red reverse

      [sendemail]
        smtpEncryption = tls
        smtpServer = smtp.gmail.com
        smtpUser = ${userData.jtojnar.email}
        smtpServerPort = 587

      [credential]
        helper = libsecret
    '';
  };

  users.extraUsers = {
    root = {
      hashedPassword = "*";
    };

    jtojnar = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = [
        "wheel"
        "dialout" # for serial
        "networkmanager"
        "wireshark"
        "docker"
        "kvm"
        "vboxusers"
      ];
      useDefaultShell = true;
      openssh.authorizedKeys.keys = keys.jtojnar;

      # generated with `diceware -w en_eff` and hashed using `mkpasswd --method=sha-512 --rounds=1000000`
      # https://logs.nix.samueldr.com/nixos/2020-04-09#1586472710-1586474674;
      hashedPassword = "$6$rounds=1000000$B4206OAvwCfr$5yakyriBawsKHHYsziytYmpzgR0zjPaBgWAJEE6ir0KT0if4yX7NCan4codw48eyORNy3YFCAlVaww0mHfZg0/";
    };
  };

  home-manager.users.jtojnar = {
    imports = [
      ../../common/configs/keepassxc
    ];

    dconf.settings = {
      "org/gnome/shell"."enabled-extensions" = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "dash-to-dock@micxgx.gmail.com"
        "GPaste@gnome-shell-extensions.gnome.org"
      ];
    };

    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        editor = "subl -w";
        aliases = {
          "co" = "pr checkout";
        };
      };
    };

    programs.nix-index.enable = true;
  };

  # For agenix.
  age.sshKeyPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  users.defaultUserShell = pkgs.fish;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "21.05";

  nix = {
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

    # nix options for derivations to persist garbage collection
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';
  };
}
