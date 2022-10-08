{ lib
, fetchFromGitHub
, naerskUnstable
, makeWrapper
, pkg-config
, perl
, openssl
, python3
, napalm
, nodejs_latest
, qt6
, substituteAll
}:

let
  version = "0.12.1";
  sources = fetchFromGitHub {
    owner = "ActivityWatch";
    repo = "activitywatch";
    rev = "v${version}";
    sha256 = "sha256-pK+upMSpJlg7J8WTmImLm8TW8pMHrCihMeiT+1/nbPM=";
    fetchSubmodules = true;
  };

in

# I did not try to package the Python server due to issues with poetry2nix I encountered for aw-qt and since there is a Rust server available. The Rust server [requires unstable Rust](https://github.com/ActivityWatch/aw-server-rust/issues/116) preventing us to include it in nixpkgs.

rec {
  aw-core = python3.pkgs.buildPythonPackage rec {
    pname = "aw-core";
    inherit version;

    format = "pyproject";

    src = "${sources}/aw-core";

    nativeBuildInputs = [
      python3.pkgs.poetry
    ];

    propagatedBuildInputs = with python3.pkgs; [
      jsonschema
      peewee
      appdirs
      iso8601
      rfc3339-validator
      TakeTheTime
      strict-rfc3339
      tomlkit
      deprecation
      timeslot
      pymongo
      python-json-logger
    ];

    meta = with lib; {
      description = "Core library for ActivityWatch";
      homepage = "https://github.com/ActivityWatch/aw-core";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mpl20;
    };
  };

  aw-client = python3.pkgs.buildPythonPackage rec {
    pname = "aw-client";
    inherit version;

    format = "pyproject";

    src = "${sources}/aw-client";

    nativeBuildInputs = [
      python3.pkgs.poetry
    ];

    propagatedBuildInputs = with python3.pkgs; [
      aw-core
      requests
      persist-queue
      click
      tabulate
    ];

    meta = with lib; {
      description = "Client library for ActivityWatch";
      homepage = "https://github.com/ActivityWatch/aw-client";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mpl20;
    };
  };

  persist-queue = python3.pkgs.buildPythonPackage rec {
    version = "0.8.0";
    pname = "persist-queue";

    src = python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-vapNz8SyCpzh9cttoxFrbLj+N1J9mR/SQoVu8szNIY4=";
    };

    checkInputs = with python3.pkgs; [
      msgpack
      nose2
    ];

    checkPhase = ''
      runHook preCheck

      # Don't run mysql tests, as they don't seem to work in nix sandbox?
      rm persistqueue/tests/test_mysqlqueue.py
      nose2

      runHook postCheck
    '';

    meta = with lib; {
      description = "Thread-safe disk based persistent queue in Python";
      homepage = "https://github.com/peter-wangxu/persist-queue";
      license = licenses.bsd3;
    };
  };

  TakeTheTime = python3.pkgs.buildPythonPackage rec {
    pname = "TakeTheTime";
    version = "0.3.1";

    src = python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "2+MEU6G1lqOPni4/qOGtxa8tv2RsoIN61cIFmhb+L/k=";
    };

    checkInputs = [
      python3.pkgs.nose
    ];

    doCheck = false; # tests not available on pypi

    checkPhase = ''
      runHook preCheck

      nosetests -v tests/

      runHook postCheck
    '';

    meta = with lib; {
      description = "Simple time taking library using context managers";
      homepage = "https://github.com/ErikBjare/TakeTheTime";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mit;
    };
  };

  timeslot = python3.pkgs.buildPythonPackage rec {
    pname = "timeslot";
    version = "0.1.2";

    src = python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "oqyZhlfj87nKkodXtJBq3SwFOQxfwU7XkruQKNCFR7E=";
    };

    meta = with lib; {
      description = "Data type for representing time slots with a start and end";
      homepage = "https://github.com/ErikBjare/timeslot";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mit;
    };
  };

  aw-qt = python3.pkgs.buildPythonApplication rec {
    pname = "aw-qt";
    inherit version;

    format = "pyproject";

    src = "${sources}/aw-qt";

    nativeBuildInputs = [
      python3.pkgs.poetry
      qt6.wrapQtAppsHook
    ];

    propagatedBuildInputs = with python3.pkgs; [
      aw-core
      qt6.qtbase # Needed for qt6.wrapQtAppsHook
      qt6.qtsvg # Rendering icons in the trayicon menu
      pyqt6
      click
    ];

    # Prevent double wrapping
    dontWrapQtApps = true;

    postPatch = ''
      sed -E 's#PyQt6 = "6.3.1"#PyQt6 = "^6.4.0"#g' -i pyproject.toml
    '';

    postInstall = ''
      install -D resources/aw-qt.desktop $out/share/applications/aw-qt.desktop
      install -D resources/aw-qt.desktop $out/etc/xdg/autostart/aw-qt.desktop

      # For the actual tray icon, see
      # https://github.com/ActivityWatch/aw-qt/blob/8ec5db941ede0923bfe26631acf241a4a5353108/aw_qt/trayicon.py#L211-L218
      install -D media/logo/logo.png $out/lib/python3.10/site-packages/media/logo/logo.png

      # For .desktop file and your desktop environment
      install -D media/logo/logo.svg $out/share/icons/hicolor/scalable/apps/activitywatch.svg
      install -D media/logo/logo.png $out/share/icons/hicolor/512x512/apps/activitywatch.png
      install -D media/logo/logo-128.png $out/share/icons/hicolor/128x128/apps/activitywatch.png
    '';

    preFixup = ''
      makeWrapperArgs+=(
        "''${qtWrapperArgs[@]}"
      )
    '';

    meta = with lib; {
      description = "Tray icon that manages ActivityWatch processes, built with Qt";
      homepage = "https://github.com/ActivityWatch/aw-qt";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mpl20;
    };
  };

  aw-server-rust = naerskUnstable.buildPackage {
    name = "aw-server-rust";
    inherit version;

    root = "${sources}/aw-server-rust";

    nativeBuildInputs = [
      pkg-config
      perl
    ];

    buildInputs = [
      openssl
    ];

    overrideMain = attrs: {
      nativeBuildInputs = attrs.nativeBuildInputs or [] ++ [
        makeWrapper
      ];

      postFixup = attrs.postFixup or "" + ''
        wrapProgram "$out/bin/aw-server" \
          --prefix XDG_DATA_DIRS : "$out/share"

        mkdir -p "$out/share/aw-server"
        ln -s "${aw-webui}" "$out/share/aw-server/static"
      '';
    };

    meta = with lib; {
      description = "Cross-platform, extensible, privacy-focused, free and open-source automated time tracker";
      homepage = "https://github.com/ActivityWatch/aw-server-rust";
      maintainers = with maintainers; [ jtojnar ];
      mainProgram = "aw-server";
      platforms = platforms.linux;
      license = licenses.mpl20;
    };
  };

  aw-watcher-afk = python3.pkgs.buildPythonApplication rec {
    pname = "aw-watcher-afk";
    inherit version;

    format = "pyproject";

    src = "${sources}/aw-watcher-afk";

    nativeBuildInputs = [
      python3.pkgs.poetry
    ];

    propagatedBuildInputs = with python3.pkgs; [
      aw-client
      xlib
      pynput
    ];

    meta = with lib; {
      description = "Watches keyboard and mouse activity to determine if you are AFK or not (for use with ActivityWatch)";
      homepage = "https://github.com/ActivityWatch/aw-watcher-afk";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mpl20;
    };
  };

  aw-watcher-window = python3.pkgs.buildPythonApplication rec {
    pname = "aw-watcher-window";
    inherit version;

    format = "pyproject";

    src = "${sources}/aw-watcher-window";

    nativeBuildInputs = [
      python3.pkgs.poetry
    ];

    propagatedBuildInputs = with python3.pkgs; [
      aw-client
      xlib
    ];

    meta = with lib; {
      description = "Cross-platform window watcher (for use with ActivityWatch)";
      homepage = "https://github.com/ActivityWatch/aw-watcher-window";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mpl20;
    };
  };

  aw-webui =
    let
      # Node.js used by napalm.
      nodejs = nodejs_latest;

      stopNpmCallingHome = ''
        # Do not try to find npm in napalm-registry –
        # it is not there and checking will slow down the build.
        npm config set update-notifier false
        # Same for security auditing, it does not make sense in the sandbox.
        npm config set audit false
      '';
    in
      napalm.buildPackage "${sources}/aw-server-rust/aw-webui" {
        patches = [
          # Hardcode version to avoid the need to have the Git repo available at build time.
          (substituteAll {
            src = ./commit-hash.patch;
            commit_hash = sources.rev;
          })
        ];

        nativeBuildInputs = [
          # deasync uses node-gyp
          python3
        ];

        npmCommands = [
          # Let’s install again, this time running scripts.
          "npm ci --loglevel verbose --nodedir=${nodejs}/include/node"

          # Build the front-end.
          "npm run build"
        ];

        postConfigure = ''
          # configurePhase sets $HOME
          ${stopNpmCallingHome}
        '';

        installPhase = ''
          runHook preInstall
          mv dist $out
          runHook postInstall
        '';
      };
}
