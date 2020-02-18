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
    (s: builtins.removeAttrs s [ "date" ])
    fetchgit
  ];

  nativeBuildInputs = [
    git
  ];

  preBuild = ''
    make generate
  '';

  modSha256 = "sha256-J/4Bpgjz7+oP82m8IaYn1CZGc7P3SH3A0nWPLM+Aw8U=";

  passthru = {
    updateScript = ./update.py;
  };

  meta = {
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
  };
}
