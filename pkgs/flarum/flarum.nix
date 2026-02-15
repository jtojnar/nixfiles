{
  stdenv,
  fetchFromGitHub,
  php,
}:

php.buildComposerProject (finalAttrs: {
  pname = "flarum";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "flarum";
    repo = "flarum";
    rev = "v${finalAttrs.version}";
    hash = "sha256-kigUZpiHTM24XSz33VQYdeulG1YI5s/M02V7xue72VM=";
  };

  # Cannot just use `vendorHash` since we need to pass `postPatch`
  # to `composerRepository` so that it can see the modified `composer.json`.
  composerRepository = php.mkComposerRepository {
    inherit (finalAttrs)
      pname
      version
      src
      postPatch
      ;
    composerNoDev = true;
    composerNoPlugins = true;
    composerNoScripts = true;
    vendorHash = "sha256-UVlDXDFkTyzGXqQgNnynXZDmquV7JC6VTwv/Zx5sJng=";
  };

  postPatch = ''
    # Cache directory path will be supplied by systemd service.
    substituteInPlace site.php \
      --replace-fail \
        "'storage' => __DIR__.'/storage'" \
        "'storage' => \$_ENV['CACHE_DIRECTORY'] ?? __DIR__.'/storage'"

    # Update script adds extensions to `composer.json` from `src`
    # and generates `composer.lock` for reproducibility, storing them
    # in our repo. Let’s bring them back into the package.
    cp "${./composer.lock}" "composer.lock"
    cp "${./composer.json}" "composer.json"
    chmod +w "composer.json" "composer.lock"

    # The CLI program is not executable for some reason.
    chmod +x flarum
  '';

  postInstall = ''
    # Move stuff back to root directory for ease of use.
    mv "$out/share/php/flarum/"{*,.nginx.conf} "$out"
    rm "$out/share/php/flarum/.editorconfig"
    rmdir "$out/share"{/php{/flarum,},}

    # Remove directories Flarum wants to write to,
    # our combiner will add symlinks to mutable paths in their stead.
    # Ensure they are NOT ACCESSIBLE through the web server.
    rm -r "$out/public/assets"
  '';

  passthru = {
    updateScript = ./update.sh;
  };
})
