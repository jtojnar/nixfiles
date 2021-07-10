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
    rev = "9d05992edb9b00d876a7bc02c6f1dfd7261f9e28";
    sha256 = "tCBIu2VlAOvEpvcgu8ybzjlR92dioft6Hhhq9eJTweU=";
  };

  wrcq-deps = napalm.buildPackage src {
    postConfigure = stopNpmCallingHome;
  };
in
  runCommand "wrcq" {
    version = "unstable-2021-07-08";

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

    mkdir -p $out
    cp -r * $out
  ''
