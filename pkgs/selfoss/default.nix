{ stdenv
, fetchurl
, lib
, unzip
}:

stdenv.mkDerivation rec {
  pname = "selfoss";
  version = "2.19-6e74ffa";

  src = fetchurl {
    url = "https://dl.cloudsmith.io/public/fossar/selfoss-git/raw/names/selfoss.zip/versions/${version}/selfoss-${version}.zip";
    sha256 = "1sk8ji6qf0icshzzlgq1aqw7g34clcbkj46wkgkp92k4wr8nljxh";
  };

  nativeBuildInputs = [
    unzip
  ];

  installPhase = ''
    runHook preInstall

    # Enable debug mode.
    substituteInPlace src/common.php --replace "\$f3->set('DEBUG', 0);" "\$f3->set('DEBUG', 1);"

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
