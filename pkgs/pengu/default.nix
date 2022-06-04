{
  runCommand,
  fetchFromGitHub,
  napalm,
  nodejs_latest,
  python3,
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

  nodejs = nodejs_latest;

  src = fetchFromGitHub {
    owner = "jtojnar";
    repo = "pengu";
    rev = "ad24f1faa1b2501ec097fd134d3769f214b40466";
    sha256 = "sha256-TDUCnl6bK6Mnp/5oQx/c59LjSXOTRVCrbqzxILVEytU=";
  };
in
napalm.buildPackage src rec {
  pname = "pengu";
  version = "unstable-2022-05-20";

  customPatchPackages = {
    # Patch shebangs.
    "node-gyp-build" = pkgs: prev: {
    };
  };

  nativeBuildInputs = [
    # For node-gyp
    python3
  ];

  inherit nodejs;

  npmCommands = [
    # Let’s install again, this time running scripts.
    "npm install --loglevel verbose --nodedir=${nodejs}/include/node"

    # Patch shebangs so that scripts can run.
    # napalm’s patching is not “overzealous” enough
    # to fix the file linked by “node_modules/.bin/parcel”.
    "patchShebangs node_modules/parcel/lib/bin.js"

    # Build the front-end.
    "npm run build"

    # Clean up node_modules for production.
    "npm install --only=production --loglevel verbose"
  ];

  postConfigure = ''
    # configurePhase sets $HOME
    ${stopNpmCallingHome}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r * "$out"

    mkdir -p "$out/lib/systemd/system"
    echo > "$out/lib/systemd/system/pengu.service" "
    [Unit]
    After=network.target
    After=postgresql.service
    Description=Pengu virtual chat

    [Service]
    ExecStart=${nodejs}/bin/node $out/src
    Restart=always
    RestartSec=10
    WorkingDirectory=$out
    "

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
