{
  runCommand,
  fetchFromGitHub,
  nodejs_latest,
  napalm,
  unstableGitUpdater,
}:

let
  nodejs = nodejs_latest;

  stopNpmCallingHome = ''
    # Do not try to find npm in napalm-registry –
    # it is not there and checking will slow down the build.
    npm config set update-notifier false

    # Same for security auditing, it does not make sense in the sandbox.
    npm config set audit false
  '';

  src = fetchFromGitHub {
    owner = "jtojnar";
    repo = "pengu";
    rev = "2d547241feed1b2a1b9515c1cd45d6f3d90246ea";
    sha256 = "sha256-UbQs2ga1Kjg+BwSFVdOhOuQz5wlGRHET7XY5fQdoHsg=";
  };

  pengu-deps = napalm.buildPackage src {
    npmCommands = [
      # Just download and unpack all the npm packages,
      # we need napalm to patch shebangs before we can run install scripts.
      "npm install --loglevel verbose --ignore-scripts"
    ];

    postConfigure = stopNpmCallingHome;

    postBuild = ''
      # Patch shebangs so that scripts can run.
      for f in node_modules/.bin/node-gyp-build node_modules/.bin/parcel; do
          patchShebangs "$(readlink -f "$f")"
      done

      # Let’s install again, this time running scripts.
      npm install --loglevel verbose
    '';
  };
in
  runCommand "pengu" {
    version = "unstable-2021-07-03";

    nativeBuildInputs = [
      nodejs
    ];

    passthru = {
      inherit src;
      updateScript = unstableGitUpdater {
        # The updater tries src.url by default, which does not exist for fetchFromGitHub (fetchurl).
        url = "${src.meta.homepage}.git";
      };
    };
  } ''
    # Required for npm config.
    export HOME=$(mktemp -d)

    cp -r ${pengu-deps}/* .
    chmod +w -R _napalm-install
    cd _napalm-install

    ${stopNpmCallingHome}

    # Build the front-end.
    npm run build
    # Clean up node_modules.
    npm install --production  --loglevel verbose

    mkdir -p $out
    cp -r * $out
  ''
