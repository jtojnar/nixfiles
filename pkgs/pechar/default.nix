{
  fetchFromGitHub,
  lib,
  buildNpmPackage,
  unstableGitUpdater,
  _experimental-update-script-combinators,
  common-updater-scripts,
}:

buildNpmPackage {
  pname = "pechar";
  version = "0-unstable-2024-07-13";

  src = fetchFromGitHub {
    owner = "ogioncz";
    repo = "pechar";
    rev = "1760e5be614be0614d432089e5bb283109898084";
    hash = "sha256-0mMxzFgA6jmpi+2NV5daA5VphvWeCT+91AlZwTpZlEM=";
  };

  npmDepsHash = "sha256-ta1LWOXZauxyQHk/pCna/RaVQ1dA7XFi+62bd26Sbdg=";

  env = {
    MEDIA_SERVER_URI = "https://mediacache.fan-club-penguin.cz";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r data/ dist/* "$out"

    runHook postInstall
  '';

  passthru.updateScript =
    let
      updateSource = unstableGitUpdater { };
      updateDeps = [
        (lib.getExe' common-updater-scripts "update-source-version")
        "pechar"
        "--ignore-same-version"
        "--source-key=npmDeps"
      ];
    in
    _experimental-update-script-combinators.sequence [
      updateSource
      updateDeps
    ];

  meta = {
    description = "Outfit editor for Club Penguin";
    homepage = "https://github.com/ogioncz/pechar";
    license = lib.licenses.cc-by-sa-40;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
