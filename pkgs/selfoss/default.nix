{ stdenv
, fetchurl
, lib
, unzip
}:

stdenv.mkDerivation rec {
  pname = "selfoss";
  version = "2.19-efe8511";

  src = fetchurl {
    url = "https://dl.cloudsmith.io/public/fossar/selfoss-git/raw/names/selfoss.zip/versions/${version}/selfoss-${version}.zip";
    sha256 = "7F7cTHa9nq0EEx0Gkb4M76Y8EguSH7b5NLRtEWVOE5k=";
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
