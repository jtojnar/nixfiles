{
  stdenv,
  fetchurl,
  lib,
  unzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "selfoss";
  version = "2.20-6d69768";

  src = fetchurl {
    url = "https://dl.cloudsmith.io/public/fossar/selfoss-git/raw/names/selfoss.zip/versions/${finalAttrs.version}/selfoss-${finalAttrs.version}.zip";
    hash = "sha256-kSMEnvMTVvznxOaYXniC0vCgOYXTh+uQY0iQprkK2cY=";
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
})
