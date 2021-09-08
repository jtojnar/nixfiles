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
  version = "unstable-2021-09-08";

  src = fetchFromGitea {
    domain = "kolaente.dev";
    owner = "vikunja";
    repo = "frontend";
    rev = "4f305b28fdf769c813ca4bdc5702d17376da2cdf";
    sha256 = "0gvdabps3mvwcnqipajr6v6922n1z6g03m5pfiw3qqzlxlybd9zw";
  };

  frontend-modules = mkYarnPackage rec {
    name = "vikunja-frontend-modules";
    inherit version src;

    doDist = false;
  };

  esbuildCustom = esbuild.overrideAttrs (old:
    let
      # Version of esbuild required by vite.
      # It should complain when not matching.
      version = "0.12.20";

      src = fetchFromGitHub {
        owner = "evanw";
        repo = "esbuild";
        rev = "v${version}";
        sha256 = "40r0f+bzzD0M97pbiSoVSJvVvcCizQvw9PPeXhw7U48=";
      };
    in
    rec {
      name = "esbuild-${version}";
      inherit src;
      go-modules = (buildGoModule {
        inherit name src;
        vendorSha256 = "2ABWPqhK2Cf4ipQH7XvRrd+ZscJhYPc3SV2cGT0apdg=";
      }).go-modules;
    }
  );
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
