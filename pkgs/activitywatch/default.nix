{ lib
, fetchFromGitHub
, naerskUnstable
, pkg-config
, perl
, openssl
, runCommand
, npmlock2nix
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

# The GUI app is [stuck on Python 3.6](https://github.com/ActivityWatch/activitywatch/issues/491), with which some of our python packages no longer build. I also tried using poetry2nix but without much success. Fortunately, it is not required.

# I did not try to package the Python server due to issues with poetry2nix I encountered for aw-qt and since there is a Rust server available. The Rust server [requires unstable Rust](https://github.com/ActivityWatch/aw-server-rust/issues/116) preventing us to include it in nixpkgs.

rec {
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
