{
  stdenv,
  lib,
  fetchFromGitHub,
  c4,
  php,
  unstableGitUpdater,
}:

stdenv.mkDerivation rec {
  pname = "flarum-webhooks-telegram-bridge";
  version = "unstable-2022-05-28";

  src = fetchFromGitHub {
    owner = "ogioncz";
    repo = "flarum-webhooks-telegram-bridge";
    rev = "ad47c3d19c69a1f2f8c6fb01f1d9d149aee74a5c";
    sha256 = "Wzf9sYujjksDwcQ1Ax/IBjw8wJeg0JBh5A1rCyvRIAs=";
  };

  composerDeps = c4.fetchComposerDeps {
    inherit src;
    includeDev = false;
  };

  nativeBuildInputs = [
    php.packages.composer
    c4.composerSetupHook
  ];

  installPhase = ''
    runHook preInstall

    cp -r . "$out"

    runHook postInstall
  '';

  passthru = {
    updateScript = unstableGitUpdater {
      url = "${meta.homepage}.git";
    };
  };

  meta = {
    description = "Bridge between Flarum Webhooks extension and Telegram";
    homepage = "https://github.com/ogioncz/flarum-webhooks-telegram-bridge";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
