{
  runCommand,
  fetchFromGitHub,
  napalm,
  unstableGitUpdater,
}:

let
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
in
napalm.buildPackage src rec {
  name = "pengu-${version}";
  version = "unstable-2021-07-03";

  npmCommands = [
    # Just download and unpack all the npm packages,
    # we need napalm to patch shebangs before we can run install scripts.
    "npm install --loglevel verbose --ignore-scripts"

    # Let’s install again, this time running scripts.
    "npm install --loglevel verbose"

    # Patch shebangs so that scripts can run.
    # napalm’s patching is not “overzealous” enough
    # to fix the file linked by “node_modules/.bin/parcel”.
    "patchShebangs node_modules/parcel/lib/bin.js"

    # Build the front-end.
    "npm run build"

    # Clean up node_modules for production.
    "npm install --production --loglevel verbose"
  ];

  postConfigure = ''
    # configurePhase sets $HOME
    ${stopNpmCallingHome}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r * $out

    runHook postInstall
  '';

  passthru = {
    inherit src;
    updateScript = unstableGitUpdater {
      # The updater tries src.url by default, which does not exist for fetchFromGitHub (fetchurl).
      url = "${src.meta.homepage}.git";
    };
  };
}
