{ stdenv
, lib
, buildGoModule
, fetchgit
, git
}:

buildGoModule rec {
  name = "vikunja-api";

  src = fetchgit {
    url = "https://kolaente.dev/vikunja/api.git";
    rev = "91a3b7aba2f0b99a1e8131ff5f7bf88d535c1cf5";
    sha256 = "sha256-RW1wcLptQZwD6pGR+iGRCWw2zXN8T8Q6SgTtCCbixnM=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    git
  ];

  preBuild = ''
    make generate
  '';

  modSha256 = "sha256-7RA35lIbGZ/IjNOLqRNMdlzppHlhA5xlUPUzjuZ09MA=";

  passthru = {
    updateScript = ./update.py;
  };

  meta = {
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
  };
}
