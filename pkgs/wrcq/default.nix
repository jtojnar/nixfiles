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
  version = "0-unstable-2024-10-22";

  src = fetchFromGitHub {
    owner = "jtojnar";
    repo = "wrcq";
    rev = "3ac679cab073f18e8f1851ee70b672509fe9ce39";
    hash = "sha256-OBYxzBMXk9tbasme8XSLmE62WOBgwEfRv1zrwXNONlU=";
  };

  npmDepsHash = "sha256-QWQFKjBhrood3ovDGsMD7AyxEiPs88vbhJVfYGeyUaM=";

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
