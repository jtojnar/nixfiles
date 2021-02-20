{ stdenv
, lib
, buildGoModule
, fetchgit
, mage
, writeShellScriptBin
}:

buildGoModule rec {
  pname = "vikunja-api";
  version = "v0.16.0-78-g393a3bc37a";

  src = fetchgit {
    url = "https://kolaente.dev/vikunja/api.git";
    rev = "393a3bc37abc9d48ab1b1fa9a3b60347bba3b42c";
    sha256 = "sha256-HDxxnrJ/EA6jHym0rIz93ePTappFC2Cv0yxVQwiurgk=";
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

  vendorSha256 = "sha256-IVcEBc1D2u5L2UHgONe8tuMzPHhH8Ze9hi0LYmGf8xI=";

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
