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
  version = "0-unstable-2024-11-16";

  src = fetchFromGitHub {
    owner = "jtojnar";
    repo = "wrcq";
    rev = "5008f8205f3246f58a6e56d18ce71a3fc262f119";
    hash = "sha256-JIk3qLYxuaEq8MsRZVVm7djw3P5PKRbOB0Vo2m9/Gf4=";
  };

  npmDepsHash = "sha256-uooo15YOXRQtCjA7IFd7CUxoUkPSGNRd0DxYZ029PKE=";

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
