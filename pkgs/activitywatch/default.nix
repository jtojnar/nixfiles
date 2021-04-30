{ lib
, fetchFromGitHub
, naerskUnstable
, makeWrapper
, pkg-config
, perl
, openssl
, python3
, runCommand
, npmlock2nix
, libsForQt5
, xdg-utils
}:

let
  version = "unstable-2020-04-22";

  sources = fetchFromGitHub {
    owner = "ActivityWatch";
    repo = "activitywatch";
    rev = "d39648092fa8fa1adff0809b2f9bccdde99537af";
    sha256 = "3Sz+Vjn20cfD5UnR3pvevX+icU8l//uNMOkfnRp/+NU=";
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
      python-json-logger
      TakeTheTime
      pymongo
      strict-rfc3339
      timeslot
    ];

    postPatch = ''
      sed -E 's#python-json-logger = "\^0.1.11"#python-json-logger = "^2.0"#g' -i pyproject.toml
    '';

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
    ];

    meta = with lib; {
      description = "Client library for ActivityWatch";
      homepage = "https://github.com/ActivityWatch/aw-client";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mpl20;
    };
  };

  persist-queue = python3.pkgs.buildPythonPackage rec {
    version = "0.6.0";
    pname = "persist-queue";

    src = python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "5z3WJUXTflGSR9ljaL+lxRD95mmZozjW0tRHkNwQ+Js=";
    };

    checkInputs = with python3.pkgs; [
      msgpack
      nose2
    ];

    checkPhase = ''
      runHook preCheck

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
      python3.pkgs.pyqt5 # for pyrcc5
      libsForQt5.wrapQtAppsHook
      xdg-utils
    ];

    propagatedBuildInputs = with python3.pkgs; [
      aw-core
      pyqt5
      click
    ];

    # Prevent double wrapping
    dontWrapQtApps = true;

    postPatch = ''
      sed -E 's#\bgit = ".+?"#version = "*"#g' -i pyproject.toml
    '';

    preBuild = ''
      make aw_qt/resources.py
    '';

    postInstall = ''
      install -Dt $out/etc/xdg/autostart resources/aw-qt.desktop
      xdg-icon-resource install --novendor --size 32 media/logo/logo.png activitywatch
      xdg-icon-resource install --novendor --size 512 media/logo/logo.png activitywatch
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
      platforms = platforms.linux;
      license = licenses.mpl20;
    };
  };

  aw-watcher-afk = python3.pkgs.buildPythonApplication rec {
    pname = "aw-watcher-afk";
    inherit version;

    format = "pyproject";

    # src = "${sources}/aw-watcher-afk";
    src = fetchFromGitHub {
      owner = "ActivityWatch";
      repo = "aw-watcher-afk";
      # https://github.com/ActivityWatch/aw-watcher-afk/pull/48
      rev = "f39dfa1d06ffe73c5ed58a10e01cc6438c63ab17";
      sha256 = "8+mdispLHJeNK7P+tGsTlNCvjT0PRB9CeJpwIPx6GqM=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [
      python3.pkgs.poetry
    ];

    propagatedBuildInputs = with python3.pkgs; [
      aw-core
      aw-client
      xlib
      pynput
    ];

    postPatch = ''
      sed -E 's#\bgit = ".+?"#version = "*"#g' -i pyproject.toml
      sed -E 's#python-xlib = \{ version = "\^0.28"#python-xlib = \{ version = "^0.29"#g' -i pyproject.toml
    '';

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

    postPatch = ''
      sed -E 's#\bgit = ".+?"#version = "*"#g' -i pyproject.toml
      sed -E 's#python-xlib = \{version = "\^0.28"#python-xlib = \{ version = "^0.29"#g' -i pyproject.toml
    '';

    meta = with lib; {
      description = "Cross-platform window watcher (for use with ActivityWatch)";
      homepage = "https://github.com/ActivityWatch/aw-watcher-window";
      maintainers = with maintainers; [ jtojnar ];
      license = licenses.mpl20;
    };
  };

  aw-webui =
    let
      webui-src = runCommand "webui-src" {} ''
        cp -r "${sources}/aw-server-rust/aw-webui" "$out"
        chmod +w "$out" "$out/package-lock.json"

        # Bypass query string in URL producing invalid derivation name.
        # https://github.com/nmattia/napalm/issues/30
        sed -Ei 's#\?cache=0&other_urls[^"]+##' "$out/package-lock.json"

        # Some packages resolved to Taobao registry, which does not seem to get substituted.
        sed -Ei 's#https://registry.npm.taobao.org/(.+?)/download/#https://registry.npmjs.org/\1/-/#' "$out/package-lock.json"
      '';
    in
      npmlock2nix.build {
        src = webui-src;
        installPhase = "cp -r dist $out";
      };
}
