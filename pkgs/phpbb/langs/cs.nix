{ fetchzip
, lib
}:

let
  version = "3.3.2";
in
fetchzip rec {
  name = "phpbb-lang-cs-${version}";

  url = "https://www.phpbb.cz/download/phpbb${version}_lang_cs.zip";
  sha256 = "ps8s7sM5F01H1AT6CuaN3AYQEsMFSS53WTtXSO++SaE=";

  stripRoot = false;

  postFetch = ''
    # We do not want VigLink extension.
    rm -r $out/ext
  '';

  meta = {
    description = "Czech phpBB translation";
    homepage = "https://www.phpbb.cz/";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
