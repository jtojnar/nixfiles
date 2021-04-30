{ lib
, fetchFromGitHub
, naerskUnstable
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
    pname = "aw-server-rust";
    inherit version;

    root = "${sources}/aw-server-rust";

    nativeBuildInputs = [
      pkg-config
      perl
    ];

    buildInputs = [
      openssl
    ];

    postInstall = ''
      mkdir "$out/bin/aw_server_rust"
      ln -s "${aw-webui}" "$out/bin/aw_server_rust/static"
    '';

    meta = with lib; {
      description = "Cross-platform, extensible, privacy-focused, free and open-source automated time tracker";
      homepage = "https://activitywatch.net/";
      maintainers = with maintainers; [ jtojnar ];
      platforms = platforms.linux;
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
