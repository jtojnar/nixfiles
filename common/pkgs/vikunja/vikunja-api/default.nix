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
    rev = "b4771c1bced504b0a53364ae4ad45749c1282656";
    sha256 = "sha256-FWxe//vEGT7jMCDd2GzoxKPNPDUQ/xPAFRTj+ZcBSlY=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    git
  ];

  preBuild = ''
    # GOFLAGS defined in the Makefile takes precedence over the environment variable so we need to pass them different way.
    export EXTRA_GOFLAGS="$GOFLAGS"
    make generate
  '';

  vendorSha256 = "sha256-gaRZBYOQWnmoV46aR73x5XHNgCQ2UEVHy159fpS9cXY=";

  # Cannot locate text fixtures.
  doCheck = false;

  passthru = {
    updateScript = [ ./update.py "vikunja-api" ];
  };

  meta = {
    description = "Back-end for Vikunja to-do list app";
    homepage = "https://vikunja.io/";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
