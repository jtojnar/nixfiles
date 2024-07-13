{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs,
  unstableGitUpdater,
  _experimental-update-script-combinators,
  common-updater-scripts,
}:

buildNpmPackage {
  pname = "wrcq";
  version = "0-unstable-2022-09-01";

  src = fetchFromGitHub {
    owner = "jtojnar";
    repo = "wrcq";
    rev = "e0f59a513644a2f9dd4937b9a06a36c8d6cdb45f";
    hash = "sha256-s1jS9xWZ58CrMaM1KAxfUKHmQJDP2VJrB2tzCsD5QGw=";
  };

  npmDepsHash = "sha256-OnEaWyPP+kXaRu4eEeNFJFjsWmCk6Buh8GPafmHxOpg=";

  # No `build` script.
  dontNpmBuild = true;

  postInstall = ''
    # Move stuff back to root directory for ease of use.
    mv "$out/lib/node_modules/wrcQ/"* "$out"
    rm "$out/lib/node_modules/wrcQ/.envrc"
    rmdir "$out/lib/node_modules/"{wrcQ,}

    # Install systemd service.
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
  '';

  passthru.updateScript =
    let
      updateSource = unstableGitUpdater { };
      updateDeps = [
        (lib.getExe' common-updater-scripts "update-source-version")
        "wrcq"
        "--ignore-same-version"
        "--source-key=npmDeps"
      ];
    in
    _experimental-update-script-combinators.sequence [
      updateSource
      updateDeps
    ];
}
