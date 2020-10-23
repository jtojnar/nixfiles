{ stdenv
, lib
, buildGoModule
, fetchgit
, mage
, writeShellScriptBin
}:

buildGoModule rec {
  pname = "vikunja-api";
  version = "v0.15.0-6-gffce9b51cc";

  src = fetchgit {
    url = "https://kolaente.dev/vikunja/api.git";
    rev = "ffce9b51ccd8ebfe938e181df4fb3e7c433da91d";
    sha256 = "sha256-XWk4gePxYbj5I05xA0xltS/qNbM2OoVqnkUqRw13Vq0=";
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

  vendorSha256 = "sha256-AWjIaJ1yAtKifBx8P6G9OZdOpzSHd3SJ/HLm70CuEFM=";

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
