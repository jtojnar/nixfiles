{
  stdenv,
  fetchurl,
  lib,
  unzip,
}:

stdenv.mkDerivation rec {
  pname = "selfoss";
  version = "2.20-9bcd66a";

  src = fetchurl {
    url = "https://dl.cloudsmith.io/public/fossar/selfoss-git/raw/names/selfoss.zip/versions/${version}/selfoss-${version}.zip";
    sha256 = "f+Qj08nrZt8L1kVMXdS0W8mkYAtqzZERfZrHHvXVOso=";
  };

  nativeBuildInputs = [
    unzip
  ];

  installPhase = ''
    runHook preInstall

    cp -r . $out

    runHook postInstall
  '';

  passthru = {
    updateScript = ./update.sh;
  };

  meta = {
    description = "Multipurpose RSS reader and aggregation web app";
    homepage = "https://selfoss.aditu.de";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
