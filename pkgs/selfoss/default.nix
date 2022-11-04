{ stdenv
, fetchurl
, lib
, unzip
}:

stdenv.mkDerivation rec {
  pname = "selfoss";
  version = "2.20-2417f4a";

  src = fetchurl {
    url = "https://dl.cloudsmith.io/public/fossar/selfoss-git/raw/names/selfoss.zip/versions/${version}/selfoss-${version}.zip";
    sha256 = "qu5SItyukvAceYg8x6yNWrHCSb6ugnGaM9xgdqgdSNY=";
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
