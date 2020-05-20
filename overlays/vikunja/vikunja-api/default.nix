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
    rev = "cc47d11792079e1abd0d997c898607b023efb196";
    sha256 = "sha256-DbG9ou6sL6Q4AsjRss1Ltxufgy+2dAjWfBm0sbrmRdA=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    git
  ];

  preBuild = ''
    make generate
  '';

  deleteVendor = true;
  vendorSha256 = "sha256-FD/g6Vv8+Zv+gSbg1kqrCQQ7JJ4nTAiD7Vzt7GIbAdc=";

  passthru = {
    updateScript = ./update.py;
  };

  meta = {
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
  };
}
