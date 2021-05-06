{ stdenv
, lib
, buildGoModule
, fetchgit
, mage
, writeShellScriptBin
}:

buildGoModule rec {
  pname = "vikunja-api";
  version = "v0.16.0-156-g06cc0a06e4";

  src = fetchgit {
    url = "https://kolaente.dev/vikunja/api.git";
    rev = "06cc0a06e4d0d2d71e16d8a54a729932eb8db9e8";
    sha256 = "sha256-t1ioo4d2L7d23BzihwYok5BD9zQnVUcBUUeEaZ8aSls=";
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

  vendorSha256 = "sha256-8u87forY0r6GMmKskqL1HJQ5qYnukBC4EHH1Y0xAcns=";

  buildPhase = ''
    runHook preBuild

    # Fixes “Error: error compiling magefiles” during build.
    export HOME=$(mktemp -d)

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
