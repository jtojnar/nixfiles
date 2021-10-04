{
  fetchFromGitHub,
  lib,
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
    owner = "ogioncz";
    repo = "pechar";
    rev = "a4baddf4d59499612c927a2b0f457ebb37c3ee3c";
    sha256 = "RB1kBkcLXu5+zqBoIzTMYSCwsNgEt+TF9GHgHQUvQbs=";
  };
in
napalm.buildPackage src rec {
  # Napalm will default to value from package.json otherwise.
  pname = "pechar";
  version = "unstable-2021-06-09";

  MEDIA_SERVER_URI = "https://mediacache.fan-club-penguin.cz";

  npmCommands = [
    # Just download and unpack all the npm packages,
    # we need napalm to patch shebangs before we can run install scripts.
    "npm install --loglevel verbose --ignore-scripts"
    # Let’s install again, this time running scripts.
    "npm install --loglevel verbose"

    # napalm only patches shebangs for scripts in bin directories
    "patchShebangs node_modules/parcel/lib/bin.js"

    # Build the front-end.
    "npm run build"
  ];

  postConfigure = stopNpmCallingHome;

  installPhase = ''
    runHook preInstall
    mv dist $out
    mv data $out/
    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater {
    # The updater tries src.url by default, which does not exist for fetchFromGitHub (fetchurl).
    url = "${src.meta.homepage}.git";
  };

  meta = {
    description = "Outfit editor for Club Penguin";
    homepage = "https://github.com/ogioncz/pechar";
    license = lib.licenses.cc-by-sa-40;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
