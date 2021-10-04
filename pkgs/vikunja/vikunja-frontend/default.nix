{ stdenv
, lib
, mkYarnPackage
, fetchFromGitea
, fetchFromGitHub
, buildGoModule
, yarn
, esbuild
, apiBase ? "/api/v1"
, unstableGitUpdater
}:

let
  version = "unstable-2021-10-03";

  src = fetchFromGitea {
    domain = "kolaente.dev";
    owner = "vikunja";
    repo = "frontend";
    rev = "b59b5def57e93f9ad68b768dedffe388926ba3b4";
    sha256 = "C1QibnYeI/Kex5k6OPi9+79eSwb81Ei9036XMAEaFXY=";
  };

  frontend-modules = mkYarnPackage rec {
    name = "vikunja-frontend-modules";
    inherit version src;

    doDist = false;
  };

  esbuildCustom = esbuild.override (old: {
    buildGoModule = attrs: old.buildGoModule (attrs // rec {
      # Version of esbuild required by vite.
      # It should complain when not matching.
      version = "0.13.3";

      src = fetchFromGitHub {
        owner = "evanw";
        repo = "esbuild";
        rev = "v${version}";
        sha256 = "JACy4h/UKcrIq5taHCRWhW94pmrsMLFXTF7GTj+IdA0=";
      };

      vendorSha256 = "QPkBR+FscUc3jOvH7olcGUhM6OW4vxawmNJuRQxPuGs=";
    });
  });
in stdenv.mkDerivation {
  pname = "vikunja-frontend";
  inherit version src;

  nativeBuildInputs = [
    frontend-modules
    yarn
  ];

  buildPhase = ''
    # Cannot use symlink or postcss-loader will crap out
    cp -r ${frontend-modules}/libexec/vikunja-frontend/node_modules/ .

    export ESBUILD_BINARY_PATH="${esbuildCustom}/bin/esbuild"
    yarn --offline run build
    # Unfortunately, this needs to be hardcoded at build.
    sed -i 's#http://localhost:3456/api/v1#${apiBase}#g' dist/index.html
  '';

  installPhase = ''
    cp -r dist $out
  '';

  passthru = {
    updateScript = unstableGitUpdater {
      # The updater tries src.url by default, which does not exist for fetchFromGitHub (fetchurl).
      url = "${src.meta.homepage}.git";
    };
    inherit frontend-modules;
  };

  meta = {
    description = "Front-end for Vikunja to-do list app";
    homepage = "https://vikunja.io/";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
