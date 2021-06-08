{
  fetchFromGitHub,
  lib,
  napalm,
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
    rev = "4760f128fa58c9cb76b936e47ffef47a7541e933";
    sha256 = "gL7oiTZXT2dkVv68ImftwDeqbG8DXSSRGkH3KGt98a0=";
  };
in
napalm.buildPackage src {
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

  meta = {
    description = "Outfit editor for Club Penguin";
    homepage = "https://github.com/ogioncz/pechar";
    license = lib.licenses.cc-by-sa-40;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
