{ runCommand, fetchFromGitHub, nodejs_latest, napalm }:

let
  nodejs = nodejs_latest;

  stopNpmCallingHome = ''
    # Do not try to find npm in napalm-registry –
    # it is not there and checking will slow down the build.
    npm config set update-notifier false

    # Same for security auditing, it does not make sense in the sandbox.
    npm config set audit false
  '';

  src = fetchFromGitHub (builtins.fromJSON (builtins.readFile ./src.json));

  wrcq-deps = napalm.buildPackage src {
    postConfigure = stopNpmCallingHome;
  };
in
  runCommand "wrcq" {
    nativeBuildInputs = [
      nodejs
    ];

    passthru = {
      inherit src;
      updateScript = ./update.sh;
    };
  } ''
    cp -r ${wrcq-deps}/* .
    chmod +w -R _napalm-install
    cd _napalm-install

    ${stopNpmCallingHome}

    # Clean up node_modules.
    npm install --production  --loglevel verbose

    mkdir -p $out
    cp -r * $out
  ''
