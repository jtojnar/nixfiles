{ stdenv
, lib
, mkYarnPackage
, fetchgit
, python2
, nodejs
, yarn
, apiBase ? "/api/v1"
}:

let
  src = lib.pipe ./src.json [
    builtins.readFile
    builtins.fromJSON
    (s: { inherit (s) url rev sha256; })
    fetchgit
  ];

  frontend-modules = mkYarnPackage rec {
    name = "vikunja-frontend-modules";

    inherit src;

    # cargo culted for node-sass
    # https://github.com/input-output-hk/cardano-explorer/blob/7f28075951f248d2a5040dd30d8403f704474df6/nix/cardano-graphql/packages.nix
    yarnPreBuild = ''
      mkdir -p $HOME/.node-gyp/${nodejs.version}
      echo 9 > $HOME/.node-gyp/${nodejs.version}/installVersion
      ln -sfv ${nodejs}/include $HOME/.node-gyp/${nodejs.version}
    '';

    pkgConfig = {
      node-sass = {
        buildInputs = [ python2 ];
        postInstall = ''
          yarn --offline run build
        '';
      };
    };

    preInstall = ''
      # for some reason the two node_modules have non-overlapping contents
      cp -r deps/vikunja-frontend/node_modules/* node_modules/
      chmod -R a+w node_modules/
    '';

    doDist = false;

    meta = {
      license = lib.licenses.gpl3Plus;
    };
  };
in stdenv.mkDerivation {
  name = "vikunja-frontend";
  inherit src;

  nativeBuildInputs = [ frontend-modules yarn ];

  buildPhase = ''
    # Cannot use symlink or postcss-loader will crap out
    cp -r ${frontend-modules}/libexec/vikunja-frontend/node_modules/ .
    yarn run build
    # Unfortunately, this needs to be hardcoded at build.
    sed -i 's#http://localhost:3456/api/v1#${apiBase}#g' dist/index.html
  '';

  installPhase = ''
    cp -r dist $out
  '';

  passthru = {
    updateScript = ./update.py;
    inherit frontend-modules;
    maintainers = with lib.maintainers; [ jtojnar ];
  };
}
