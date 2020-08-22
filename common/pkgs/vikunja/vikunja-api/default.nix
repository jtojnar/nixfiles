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
    rev = "6a82d4e2af87344a2ed51788744b4b6e97065640";
    sha256 = "sha256-C6fBZS5eG2G+c65Q7XlK9R99QIs9MaVgyGpC5nPrbqk=";
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

  vendorSha256 = "sha256-x97ny0OJSOVrQu2anLURlsZIeXqSpxCAUoUxUhayHbo=";

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
