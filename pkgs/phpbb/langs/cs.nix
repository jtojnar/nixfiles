{
  fetchFromGitHub,
  lib,
  gitUpdater,
}:

let
  version = "2024.12.23.16.25";
  self = fetchFromGitHub {
    name = "phpbb-lang-cs-${version}";

    owner = "R3gi";
    repo = "phpbb-cz";
    rev = version;
    sha256 = "gjmeURcIe356M72UbO2jz0UKYH+3kopoKdx/uqpXCCo=";

    postFetch = ''
      # We do not want VigLink extension.
      rm -r $out/ext
    '';

    passthru = {
      updateScript = gitUpdater {
        pname = "phpbb.packages.langs.cs";
        inherit version;
        url = "https://github.com/R3gi/phpbb-cz.git";
      };

      # For updateScript
      src = self;
    };

    meta = {
      description = "Czech phpBB translation";
      homepage = "https://www.phpbb.cz/";
      license = lib.licenses.gpl2Only;
      maintainers = with lib.maintainers; [ jtojnar ];
      platforms = lib.platforms.all;
    };
  };
in
self
