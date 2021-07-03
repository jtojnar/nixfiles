{ stdenv
, lib
, mkYarnPackage
, fetchFromGitea
, yarn
, apiBase ? "/api/v1"
, unstableGitUpdater
}:

let
  version = "unstable-2021-06-28";

  src = fetchFromGitea {
    domain = "kolaente.dev";
    owner = "vikunja";
    repo = "frontend";
    rev = "7e48f65ff03213b09dece8e66adf106e84c76f4c";
    sha256 = "AQCHire2IFdoiMeDR2iUYRQIDOOSzKrm/OMube3Bxt8=";
  };

  frontend-modules = mkYarnPackage rec {
    name = "vikunja-frontend-modules";
    inherit version src;

    doDist = false;
  };
in stdenv.mkDerivation {
  pname = "vikunja-frontend";
  inherit version src;

  nativeBuildInputs = [ frontend-modules yarn ];

  buildPhase = ''
    # Cannot use symlink or postcss-loader will crap out
    cp -r ${frontend-modules}/libexec/vikunja-frontend/node_modules/ .
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
