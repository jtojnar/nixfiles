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
    rev = "8ac158cdb4957bdbb34c4b9eab46447596906884";
    hash = "sha256-YBE9QdLkCUEwa+R716g/ix1JaVw63qloO5wuFxgBqv8=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    git
  ];

  preBuild = ''
    make generate
  '';

  modSha256 = "sha256-ad9jafZ8Nxeb6MbyKy0OdKYfNGeriwrWFm+RWPUp4DI=";

  passthru = {
    updateScript = ./update.py;
  };

  meta = {
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
  };
}
