{ config, inputs, pkgs, lib, ... }:

let
  keys = import ../../common/data/keys.nix;

  userData = import ../../common/data/users.nix;

  dwarffsModule =
    { pkgs, ... }@args:
    let
      originalModule = inputs.dwarffs.nixosModules.dwarffs args;
    in
      lib.mergeAttrs originalModule {
        # Prefer system debug info over dwarffs since it will be faster.
        environment.variables.NIX_DEBUG_INFO_DIRS = lib.mkAfter originalModule.environment.variables.NIX_DEBUG_INFO_DIRS;

        # Overlay is already added when creating our pkgs (and with the correct Nix).
        nixpkgs = builtins.removeAttrs originalModule.nixpkgs [ "overlays" ];
      };

      openLocalhostAsHttp = pkgs.makeDesktopItem {
        name = "localhost-proto-handler";
        desktopName = "Open localhost protocol as http";
        noDisplay = true;
        exec = "${lib.getBin pkgs.glib}/bin/gio open http://%u";
        mimeTypes = [
          "x-scheme-handler/localhost"
        ];
      };
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    dwarffsModule
    inputs.self.nixosModules.profiles.environment
    inputs.self.nixosModules.profiles.jtojnar-firefox
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

  boot.kernelModules = [
    "v4l2loopback"
    "snd_aloop"
  ];
  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback.out
  ];
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

  boot.tmp.cleanOnBoot = true;

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

  hardware = {
    # Configure sound.
    pulseaudio.enable = false; # Using PipeWire
    bluetooth = {
      enable = true;
      settings = {
        General = {
          # Battery API does not have a separate UUID.
          Experimental = "*";
        };
      };
    };

    cpu.intel.updateMicrocode = true;
  };

  environment.systemPackages = with pkgs; [
    abiword
    alejandra
    almanah
    anki-bin
    apg
    bat
    bind
    binutils # readelf, xstrings
    bustle
    cachix
    chromium
    common-updater-scripts
    config.boot.kernelPackages.v4l2loopback
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
    d-spy
    droidcam
    dos2unix
    easyeffects
    easytag
    eza
    exiftool
    fd
    file
    foliate
    fzf
    gcolor3
    gdb
    gimp
    diff-so-fancy
    evolution
    gitFull
    gitg
    git-auto-fixup
    git-auto-squash
    git-part-pick
    glade
    gnome.dconf-editor
    gnome.devhelp
    gnome.geary
    gnome.ghex
    gnome.gnome-chess
    gnome.gnome-disk-utility
    gnome.gnome-sound-recorder
    gnome.gnome-tweaks
    gnome.nautilus-python
    gnome.pomodoro
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnumeric
    gnupg
    gsmartcontrol
    libadwaita # for demo
    gtk3.dev # for gtk-builder-tool etc
    graphviz
    python3.pkgs.xdot
    htop
    icon-library
    imagemagick
    indent
    (inkscape-with-extensions.override {
      inkscapeExtensions = [
        inkscape-extensions.applytransforms
      ];
    })
    jq
    libxml2 # for xmllint
    lorri
    ltrace
    meld
    mkpasswd
    moreutils # isutf8
    ncdu
    nixpkgs-fmt
    nix-bisect
    nix-diff
    nix-explore-closure-size
    nix-index
    nix-top
    onboard
    openLocalhostAsHttp
    paprefs
    pavucontrol
    patchelf
    patchutils # for filterdiff
    playerctl
    man-pages-posix
    python3Full
    ripgrep
    sd
    signal-desktop
    sman
    solo2-cli
    sublime4-dev
    sublime-merge
    telegram-desktop
    tldr
    transmission-gtk
    treesheets
    unrar
    valgrind
    vlc
    warp
    wget
    wirelesstools # for iwlist
    xdot
    xsel
    xsv # handling CSV files
    youtube-dl
    zotero
  ];

  services.udev.packages = with pkgs; [
    teensy-udev-rules
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

    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
  };

  documentation = {
    dev.enable = true;
  };

  # List services that you want to enable:

  services.flatpak.enable = true;

  security.rtkit.enable = true;

  networking.firewall = {
    allowedTCPPortRanges = [
      # Warpinator
      { from = 42000; to = 42001; }
    ];
    allowedTCPPorts = [
      # Transmission GTK
      config.services.transmission.settings.peer-port
    ];
    allowedUDPPorts = [
      # Transmission GTK
      config.services.transmission.settings.peer-port
    ];
  };

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

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    cue = true;
    authFile = pkgs.writeText "u2f-mappings" ''
      jtojnar:owBYsYvxunFYr+6pRDPfJg44RVGGLk/CiPUQh1cUrp4dQBlbriL3Ale6Hn4FzNNcVbCz7WcETohnc3bx2gABpwQoX2ZGpFOW/eZelo/wmEOfgJPb7yP1c+mzK6CcFgza70LgStWyyYi4D17lSQTyH8hDb5c3+cGO8tPJ1qM1QcNeQhXt6IrZ5BGnZSRvHfJ0v/naqf3gV2HJXqUrIxRywVnDAgggvo2xYbARR/m3wU4MkxrvjAFMhObc5FgOdbh4x+PmAlDM8bGtII09IFQVT8AT6EST,QxF7jFLgz7FsuwcHXxUq2mQwIPdYfZXqhy1TYhsGnvmRrUMxRI+xdOyleIp1tWqTiWrDCFcu2/uCc3j21h4gfw==,es256,+presence
    '';
  };

  security.sudo.extraConfig = ''
    Defaults pwfeedback
    Defaults timestamp_timeout=25
  '';

  services.tailscale.enable = true;

  boot.plymouth.enable = true;
  services.sysprof.enable = true;
  services.fwupd.enable = true;

  programs.gnome-terminal.enable = true;
  programs.gpaste.enable = true;

  services.xserver = {
    enable = true;
    xkb = {
      layout = "cz";
      variant = "qwerty";
      options = "compose:caps";
    };
  };

  # Enable the Desktop Environment.
  services.xserver.displayManager.gdm = {
    enable = true;
    debug = true;
  };
  services.xserver.displayManager.defaultSession = "gnome-xorg";


  services.xserver.desktopManager.gnome = {
    enable = true;
  };

  i18n.inputMethod.enabled = "ibus";
  i18n.inputMethod.ibus.engines = with pkgs.ibus-engines; [
    # mozc
  ];

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

  environment.sessionVariables = {
    # Needs the hack above.
    GNUPGHOME = "$HOME/.local/share/gnupg";
  };

  systemd.user.services."org.gnome.GPaste".serviceConfig.TimeoutSec = 900;

  environment.etc = {
    "gitconfig".text = ''
      [user]
        name = ${userData.jtojnar.name}
        email = ${userData.jtojnar.email}

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
      homeMode = "755"; # allow Apache to access ~/Projects
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
      openssh.authorizedKeys.keys = keys.jtojnar ++ keys.jtojnar-redmi;

      # generated with `diceware -w en_eff` and hashed using `mkpasswd --method=sha-512 --rounds=1000000`
      # https://logs.nix.samueldr.com/nixos/2020-04-09#1586472710-1586474674;
      hashedPassword = "$6$rounds=1000000$B4206OAvwCfr$5yakyriBawsKHHYsziytYmpzgR0zjPaBgWAJEE6ir0KT0if4yX7NCan4codw48eyORNy3YFCAlVaww0mHfZg0/";
    };
  };

  home-manager.users.jtojnar = { lib, ... }: {
    imports = [
      ../../common/configs/keepassxc
      ../../common/configs/sublime
    ];

    dconf.settings = {
      "org/gnome/desktop/background" = {
        primary-color = "#000000";
        secondary-color = "#000000";
        picture-uri = "file://${pkgs.reflection_by_yuumei}";
        picture-uri-dark = "file://${pkgs.reflection_by_yuumei}";
      };

      "org/gnome/desktop/screensaver" = {
        lock-delay = lib.hm.gvariant.mkUint32 3600;
        lock-enabled = true;
        picture-uri = "file://${pkgs.undersea_city_by_mrainbowwj}";
        primary-color = "#000000";
        secondary-color = "#000000";
      };

      "org/gnome/desktop/peripherals/touchpad" = {
        click-method = "default";
      };

      "org/gnome/desktop/session" = {
        idle-delay = lib.hm.gvariant.mkUint32 900;
      };

      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = [ "<Super>i" ];
        switch-input-source-backward = [ "<Shift><Super>i" ];

        switch-applications = lib.hm.gvariant.mkArray lib.hm.gvariant.type.string [];
        switch-applications-backward = lib.hm.gvariant.mkArray lib.hm.gvariant.type.string [];
        switch-windows = [ "<Super>Tab" ];
        switch-windows-backward = [ "<Shift><Super>Tab" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        previous = ["<Super>b"];
        custom-keybindings = ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"];
        next = ["<Super>n"];
        home = ["<Super>e"];
        play = ["<Super>space"];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>t";
        command = "gnome-terminal";
        name = "Open terminal";
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
          "pomodoro@arun.codito.in"
        ];
      };

      "org/gtk/settings/file-chooser" = {
        sort-directories-first = true;
        location-mode = "path-bar";
      };

      "org/gnome/desktop/input-sources" = {
        sources = [
          (lib.hm.gvariant.mkTuple [
            "xkb"
            "${config.services.xserver.xkb.layout}${lib.optionalString (config.services.xserver.xkb.variant != "") "+" + config.services.xserver.xkb.variant}"
          ])
          (lib.hm.gvariant.mkTuple [
            "ibus"
            "mozc-jp"
          ])
        ];
        xkb-options = [
          config.services.xserver.xkb.options
        ];
      };
    };

    gtk = {
      enable = true;
      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = true;
        };
      };
    };

    home.file.".config/npm/npmrc".text = ''
      prefix=''${XDG_DATA_HOME}/npm
      cache=''${XDG_CACHE_HOME}/npm
    '';

    home.file.".config/mozc/ibus_config.textproto".text = ''
      # `ibus write-cache; ibus restart` might be necessary to apply changes.
      engines {
        name : "mozc-jp"
        longname : "Mozc"
        layout : "default"
        layout_variant : ""
        layout_option : ""
        rank : 80
      }
      # Ensure hiragana input mode is default.
      active_on_launch: True
    '';

    home.file.".XCompose".text = ''
      # The extra slash needed to convince GTK to load the file instead of an internal table.
      # https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/5150
      # Though it is only relevant for gtk-im-context-simple, which will not be used
      # while we use ibus as an input method.
      include "/%L"

      # https://unicode-table.com/en/blocks/mathematical-operators/
      <Multi_key> <A> <A> : "∀"
      <Multi_key> <E> <E> : "∃"
      <Multi_key> <N> <E> : "∄"
      <Multi_key> <i> <n> : "∈"
      <Multi_key> <n> <i> <n> : "∉"
      <Multi_key> <n> <i> : "∋"
      <Multi_key> <n> <n> <i> : "∌"
      <Multi_key> <s> <u> <m> : "∑"
      <Multi_key> <p> <r> <o> <d> : "∏"
      <Multi_key> <s> <q> <r> <t> : "√"
      <Multi_key> <s> <e> <q> : "⊆"
      <Multi_key> <S> <e> <q> : "⊇"
      <Multi_key> <n> <o> <t> : "¬"
      <Multi_key> <c> <o> <n> : "∧"
      <Multi_key> <d> <i> <s> : "∨"
      <Multi_key> <c> <a> <p> : "∩"
      <Multi_key> <c> <u> <p> : "∪"
      <Multi_key> <i> <f> <f> : "⇔"
      <Multi_key> <b> <o> <t> : "⊥"
      <Multi_key> <u> <p> : "↑"
      <Multi_key> <d> <n> : "↓"
    '';

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.gh = {
      enable = true;
      settings = {
        # Workaround for https://github.com/nix-community/home-manager/issues/4744
        version = 1;

        git_protocol = "ssh";
        editor = "subl -w";
        aliases = {
          "co" = "pr checkout";
        };
      };
    };

    programs.nix-index.enable = true;

    programs.spicetify = {
      enable = true;
      theme = pkgs.spicePkgs.themes.Default // {
        additionalCss = pkgs.spicePkgs.themes.Default.additionalCss or "" + ''
          /* Remove extra space at the top of the window. */
          .spotify__container--is-desktop .nav-ylx .Root__top-container {
            padding-top: 0;
          }
        '';
      };

      enabledCustomApps = with pkgs.spicePkgs.apps; [
        lyrics-plus
        marketplace
      ];

      enabledExtensions = with pkgs.spicePkgs.extensions; [
        playNext
        hidePodcasts
      ];
    };

    home.stateVersion = "18.09";
  };

  # For agenix.
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  users.defaultUserShell = pkgs.fish;

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "21.05";

  programs.ssh = {
    knownHosts = {
      "aarch64.nixos.community".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUTz5i9u5H2FHNAmZJyoJfIGyUm/HfGhfwnc142L3ds";
    };
  };

  nix = {
    # nix options for derivations to persist garbage collection
    settings = {
      keep-outputs = true;
      keep-derivations = true;
    };
  };
}
