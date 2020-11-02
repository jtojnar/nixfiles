{ fetchzip
, lib
}:

let
  version = "3.3.0";
in
fetchzip rec {
  name = "phpbb-lang-cs-${version}";

  url = "https://www.phpbb.cz/download/phpbb${version}_lang_cs.zip";
  sha256 = "w81HzyJJpXjFv6CqZVFU69OHW2s0DrJib635uM7LrVg=";

  stripRoot = false;

  extraPostFetch = ''
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
