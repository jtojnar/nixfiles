{ stdenv
, lib
, buildGoModule
, fetchgit
, mage
, writeShellScriptBin
}:

buildGoModule rec {
  pname = "vikunja-api";
  version = "v0.17.0-54-ge857d73c22";

  src = fetchgit {
    url = "https://kolaente.dev/vikunja/api.git";
    rev = "e857d73c229058eaefbc77f5b358e7c44cf3afbf";
    sha256 = "sha256-A0XdzKAX9YiSBqswaijPBoTP4ZEC7AXDesaalhBkcik=";
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

  vendorSha256 = "sha256-O6Ru+xC8LyReKrQ56FABwTWdXN53/H+NJqmXgAfrnyI=";

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
