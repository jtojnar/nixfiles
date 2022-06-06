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
    repo = "wrcq";
    rev = "4f5208c31ac3e38fe6c6c5d06c7a04c5af3654c2";
    sha256 = "dgbr/Lp92P54UkjiMzv2tF1q6ajLgZdPF2wOyAzwf34=";
  };

  wrcq-deps = napalm.buildPackage src {
    postConfigure = stopNpmCallingHome;
  };
in
  runCommand "wrcq" {
    version = "unstable-2021-12-11";

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

    cp -r ${wrcq-deps}/* .
    chmod +w -R _napalm-install
    cd _napalm-install

    ${stopNpmCallingHome}

    # Clean up node_modules.
    npm install --production  --loglevel verbose

    mkdir -p "$out"
    cp -r * "$out"

    mkdir -p "$out/lib/systemd/system"
    echo > "$out/lib/systemd/system/pqe.service" "
    [Unit]
    After=network.target
    After=postgresql.service
    Description=Prequalified Entrants

    [Service]
    ExecStart=${nodejs}/bin/node $out/index.js
    Restart=always
    RestartSec=10
    WorkingDirectory=$out
    "
  ''
