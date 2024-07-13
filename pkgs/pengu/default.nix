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
  pname = "pengu";
  version = "0-unstable-2023-12-20";

  src = fetchFromGitHub {
    owner = "jtojnar";
    repo = "pengu";
    rev = "29dcc190c0250b6f5268000449cddc54ca65f597";
    hash = "sha256-Osc9/tDsONdCm8U9HSgSxJr74WYeH8t72Ql//CzIb+M=";
  };

  npmDepsHash = "sha256-NLjWPwinqtClWo4z/O5osUpcqlpMPlGv7f3jiyqyTzM=";

  postInstall = ''
    # Move stuff back to root directory for ease of use.
    mv "$out/lib/node_modules/pengu/"* "$out"
    rmdir "$out/lib/node_modules"{/pengu,}

    # Install systemd service.
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
  '';

  passthru.updateScript =
    let
      updateSource = unstableGitUpdater { };
      updateDeps = [
        (lib.getExe' common-updater-scripts "update-source-version")
        "pengu"
        "--ignore-same-version"
        "--source-key=npmDeps"
      ];
    in
    _experimental-update-script-combinators.sequence [
      updateSource
      updateDeps
    ];
}
