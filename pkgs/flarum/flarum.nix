{
  stdenv,
  fetchFromGitHub,
  c4,
  php,
}:

stdenv.mkDerivation rec {
  pname = "flarum";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "flarum";
    repo = "flarum";
    rev = "v${version}";
    sha256 = "YNcWByFx7rMuFymS7+Mw31trpjUFx2Zqry9iWQBR1zw=";
  };

  composerDeps = c4.fetchComposerDeps {
    lockFile = ./composer.lock;
  };

  nativeBuildInputs = [
    php.packages.composer
    c4.composerSetupHook
  ];

  buildInputs = [
    php
  ];

  postPatch = ''
    substituteInPlace site.php \
      --replace \
        "'storage' => __DIR__.'/storage'" \
        "'storage' => \$_ENV['CACHE_DIRECTORY'] ?? __DIR__.'/storage'"
    cp "${./composer.lock}" "composer.lock"
    cp "${./composer.json}" "composer.json"
    chmod +w "composer.json" "composer.lock"

    chmod +x flarum
  '';

  installPhase = ''
    runHook preInstall

    composer --no-ansi install --no-dev
    cp -r . "$out"

    # Remove directories Flarum wants to write to,
    # our combiner will add symlinks to mutable paths in their stead.
    # Ensure they are NOT ACCESSIBLE through the web server.
    rm -r "$out/public/assets"

    runHook postInstall
  '';

  passthru = {
    updateScript = ./update.sh;
  };
}
