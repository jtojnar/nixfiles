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
    rev = "158d98c2bdc93026da15f775daec895c991c5168";
    sha256 = "sha256-RIYu7sJHUU4FctQMcmktDLcXKVN+orXmb6fnaEH0pPQ=";
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

  deleteVendor = true;
  vendorSha256 = "sha256-BecxQY7g+n57Slj28vMyI5JREl6AlLcdgZJWuGAdvzg=";

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
