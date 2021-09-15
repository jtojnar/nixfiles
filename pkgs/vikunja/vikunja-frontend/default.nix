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
  version = "unstable-2021-09-10";

  src = fetchFromGitea {
    domain = "kolaente.dev";
    owner = "vikunja";
    repo = "frontend";
    rev = "50c1a2e4d59aeedc4a9f362210a0ed6cf5da1c4e";
    sha256 = "wEDm5TDLujyHymU4D1YdZ+wlFMJuv3eMTvGZF2n2yV4=";
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
      version = "0.12.20";

      src = fetchFromGitHub {
        owner = "evanw";
        repo = "esbuild";
        rev = "v${version}";
        sha256 = "40r0f+bzzD0M97pbiSoVSJvVvcCizQvw9PPeXhw7U48=";
      };

      vendorSha256 = "2ABWPqhK2Cf4ipQH7XvRrd+ZscJhYPc3SV2cGT0apdg=";
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
