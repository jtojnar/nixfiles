{
  config,
  pkgs,
  ...
}:

let
  userData = import ../../common/data/users.nix;

  firefox = pkgs.firefox.override (args: args // {
    cfg = args.cfg or {} // {
      # nixpkgs.config NixOS option not actually passed to Nixpkgs
      # so we need to replicate this part of chrome-gnome-shell module.
      enableGnomeExtensions = true;

      speechSynthesisSupport = true;
    };

    extraPrefs = ''
      // Downloading random PDFs from http website is super annoing with this.
      lockPref("dom.block_download_insecure", false);

      // Always use XDG portals for stuff
      lockPref("widget.use-xdg-desktop-portal.file-picker", 1);

      // Enable userChrome.css
      lockPref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

      // Avoid cluttering ~/Downloads for the “Open” action on a file to download.
      lockPref("browser.download.start_downloads_in_tmp_dir", true);
    '';
  });
in

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    # Note that inotify watches consume 1kB on 64-bit machines.
    "fs.inotify.max_user_watches" = 1048576; # default: 8192
    "fs.inotify.max_user_instances" = 1024; # default: 128
    "fs.inotify.max_queued_events" = 32768; # default: 16384
    "kernel.perf_event_paranoid" = 1; # for rr, default: 2
    "kernel.sysrq" = 1; # allow all magic SysRq keys
  };

  boot.tmp.cleanOnBoot = true;

  boot.plymouth.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Select internationalisation properties.
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  i18n = {
    defaultLocale = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver = {
    # Enable the GNOME Desktop Environment.
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Configure keymap in X11
    layout = "cz";
    xkbVariant = "qwerty";
    xkbOptions = "compose:caps";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Configure sound.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware = {
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

  services.fwupd.enable = true;

  users = {
    defaultUserShell = pkgs.fish;

    extraUsers = {
      root = {
        hashedPassword = "*";
      };

      jtojnar = {
        isNormalUser = true;
        uid = 1000;
        description = userData.jtojnarWork.name;
        extraGroups = [
          "networkmanager"
          "wheel"
          "wireshark"
        ];
        useDefaultShell = true;
        passwordFile = "/etc/password-jtojnar";
      };
    };
  };

  services.fprintd.enable = true;

  security.sudo.extraConfig = ''
    Defaults pwfeedback
    Defaults timestamp_timeout=25
  '';

  home-manager.users.jtojnar = { lib, ... }: {
    imports = [
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
            "${config.services.xserver.layout}${lib.optionalString (config.services.xserver.xkbVariant != "") "+" + config.services.xserver.xkbVariant}"
          ])
        ];
        xkb-options = [
          config.services.xserver.xkbOptions
        ];
      };
    };


    home.file.".mozilla/firefox/f6a1brtw.default/chrome/userChrome.css".text = ''
      @-moz-document url(chrome://browser/content/browser.xul),
      url(chrome://browser/content/browser.xhtml) {
          #main-window[tabsintitlebar="true"]:not([extradragspace="true"]) #TabsToolbar,
          #main-window:not([tabsintitlebar="true"]) #TabsToolbar {
              visibility: collapse !important;
          }
      }
    '';

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
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

    home.stateVersion = "18.09";
  };

  environment.systemPackages = with pkgs; [
    bat
    binutils # readelf, xstrings
    chromium
    curlFull
    dos2unix
    exa
    fd
    file
    firefox
    fzf
    gdb
    gimp
    diff-so-fancy
    gitFull
    git-auto-fixup
    git-auto-squash
    git-part-pick
    gnome.dconf-editor
    gnome.devhelp
    gnome.ghex
    gnome.gnome-disk-utility
    gnome.gnome-sound-recorder
    gnome.gnome-tweaks
    gnome.nautilus-python
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    gnomeExtensions.hot-edge
    gnumeric
    graphviz
    htop
    imagemagick
    indent
    (inkscape-with-extensions.override {
      inkscapeExtensions = [
        inkscape-extensions.applytransforms
      ];
    })
    jq
    libxml2 # for xmllint
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
    pandoc
    paprefs
    pavucontrol
    patchelf
    patchutils # for filterdiff
    playerctl
    man-pages-posix
    python3Full
    ripgrep
    sd
    sman
    sublime4-dev
    sublime-merge
    thunderbird
    tldr
    unrar
    valgrind
    wget
    wirelesstools # for iwlist
    xdot
    xsel
    xsv # handling CSV files
  ];

  services.sysprof.enable = true;

  programs = {
    fish = {
      enable = true;
      interactiveShellInit =
        ''
          eval (${pkgs.direnv}/bin/direnv hook fish)
        ''
        + builtins.readFile ../../common/data/config.fish;
    };

    gnome-terminal.enable = true;
    gpaste.enable = true;

    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
  };

  documentation = {
    dev.enable = true;
  };


  environment.etc = {
    "gitconfig".text = ''
      [user]
        name = ${userData.jtojnarWork.name}
        email = ${userData.jtojnarWork.email}

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
        smtpUser = ${userData.jtojnarWork.email}
        smtpServerPort = 587

      [credential]
        helper = libsecret
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
