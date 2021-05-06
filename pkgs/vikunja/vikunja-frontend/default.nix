{ stdenv
, lib
, mkYarnPackage
, fetchgit
, yarn
, apiBase ? "/api/v1"
}:

let
  srcData = builtins.fromJSON (builtins.readFile ./src.json);

  version = "unstable-" + builtins.head (lib.splitString "T" srcData.date);

  src = fetchgit {
    inherit (srcData) url rev sha256;
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
    updateScript = ./update.py;
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
