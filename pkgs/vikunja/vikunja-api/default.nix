{ stdenv
, lib
, buildGoModule
, fetchgit
, mage
, writeShellScriptBin
}:

buildGoModule rec {
  pname = "vikunja-api";
  version = "v0.18.1-135-g614dcaeb9d";

  src = fetchgit {
    url = "https://kolaente.dev/vikunja/api.git";
    rev = "614dcaeb9d4ef1e711024a39ae2e3f5a78ee5a45";
    sha256 = "sha256-W7AocT2lWKh3iOTDu0VGgkZQaLvOmRtDo8iVJtmcR8s=";
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

  vendorSha256 = "sha256-H6SOA3VzfSbJB7u44nn3RWyasU4UU3Juy/rHWVQ5ya0=";

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
    updateScript = ./update.py;

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
