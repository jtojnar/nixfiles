{ stdenv
, lib
, buildGoModule
, fetchgit
, mage
, writeShellScriptBin
}:

buildGoModule rec {
  pname = "vikunja-api";
  version = "v0.18.1-28-gfb9fa27488";

  src = fetchgit {
    url = "https://kolaente.dev/vikunja/api.git";
    rev = "fb9fa27488ef2930ab882e5c5c7c0a94330c8b7f";
    sha256 = "sha256-U+dTYdvALGIkd4QYlL9xWyJiKizP7WE5xO0naSp5Qzg=";
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

  vendorSha256 = "sha256-VHEmAAUsZ/pU/+DAn3q7gK2Wc4efcRlA+DyiR8sedOg=";

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
