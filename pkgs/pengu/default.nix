{
  runCommand,
  fetchFromGitHub,
  napalm,
  nodejs,
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

  src = fetchFromGitHub {
    owner = "jtojnar";
    repo = "pengu";
    rev = "29dcc190c0250b6f5268000449cddc54ca65f597";
    sha256 = "sha256-Osc9/tDsONdCm8U9HSgSxJr74WYeH8t72Ql//CzIb+M=";
  };
in
napalm.buildPackage src rec {
  pname = "pengu";
  version = "unstable-2023-12-20";

  customPatchPackages = {
    # Patch shebangs.
    "node-gyp-build" = pkgs: prev: {
    };
    "node-gyp-build-optional-packages" = pkgs: prev: {
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
