{ stdenv
, lib
, buildGoModule
, fetchgit
, mage
, writeShellScriptBin
}:

buildGoModule rec {
  pname = "vikunja-api";
  version = "v0.15.0-37-g67faa26cbc";

  src = fetchgit {
    url = "https://kolaente.dev/vikunja/api.git";
    rev = "67faa26cbccf5f7598c6d6f6e8efa82c7de802fc";
    sha256 = "sha256-JkVH/alU0eW4dDnnZdusjIfizu/5Q+OfFXnwljdBCVA=";
  };

  nativeBuildInputs =
    let
      fakeGit = writeShellScriptBin "git" ''
        if [[ $@ = "${passthru.gitDescribeCommand}" ]]; then
            echo "${version}"
        else
            >&2 echo "Unknown command: $@"
            exit 1
        fi
      '';
    in [
      fakeGit
      mage
    ];

  # Wunderlist test requires network.
  doCheck = false;

  vendorSha256 = "sha256-1C9AsBl3iTlXqcD43sisncVOxxdtav+QDA2Q/zXVUd0=";

  buildPhase = ''
    runHook preBuild

    mage build:build

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    mage test:unit

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    install -Dt $out/bin vikunja

    runHook postInstall
  '';

  passthru = {
    updateScript = [ ./update.py "vikunja-api" ];

    gitDescribeCommand = "describe --tags --always --abbrev=10";
  };

  meta = {
    description = "Back-end for Vikunja to-do list app";
    homepage = "https://vikunja.io/";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
