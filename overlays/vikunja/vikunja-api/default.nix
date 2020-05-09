{ stdenv
, lib
, buildGoModule
, fetchgit
, git
}:

buildGoModule rec {
  name = "vikunja-api";

  src = lib.pipe ./src.json [
    builtins.readFile
    builtins.fromJSON
    (s: { inherit (s) url rev sha256 leaveDotGit; })
    fetchgit
  ];

  nativeBuildInputs = [
    git
  ];

  preBuild = ''
    make generate
  '';

  modSha256 = "sha256-uHMjaJiJaUYv3jquKeSCeBLdF3EdsQ5a2CpOmd9iDYA=";

  passthru = {
    updateScript = ./update.py;
  };

  meta = {
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
  };
}
