{ stdenv
, lib
, mkYarnPackage
, fetchgit
, python3
, pkg-config
, libsass
, nodejs
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

    yarnPreBuild = ''
      mkdir -p $HOME/.cache/node-gyp/${nodejs.version}

      # Set up version which node-gyp checks in <https://github.com/nodejs/node-gyp/blob/4937722cf597ccd1953628f3d5e2ab5204280051/lib/install.js#L87-L96> against the version in <https://github.com/nodejs/node-gyp/blob/4937722cf597ccd1953628f3d5e2ab5204280051/package.json#L15>.
      echo 9 > $HOME/.cache/node-gyp/${nodejs.version}/installVersion

      # Link node headers so that node-gyp does not try to download them.
      ln -sfv ${nodejs}/include $HOME/.cache/node-gyp/${nodejs.version}
    '';

    pkgConfig = {
      node-sass = {
        buildInputs = [ python3 pkg-config libsass ];
        # https://github.com/moretea/yarn2nix/issues/12#issuecomment-545084619
        postInstall = ''
          LIBSASS_EXT=auto yarn --offline run build
          rm build/config.gypi
        '';
      };
    };

    preInstall = ''
      # for some reason the two node_modules have non-overlapping contents
      cp -r deps/vikunja-frontend/node_modules/* node_modules/
      chmod -R a+w node_modules/
    '';

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
