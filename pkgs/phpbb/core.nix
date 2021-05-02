{ stdenv
, fetchurl
, lib
, unzip
}:

stdenv.mkDerivation rec {
  pname = "phpbb";
  version = "3.3.4";

  outputs = [ "out" "installer" ];

  src = fetchurl {
    url = "https://download.phpbb.com/pub/release/${lib.versions.majorMinor version}/${version}/phpBB-${version}.zip";
    sha256 = "f+oGdWf4GQ7VyEZFv1NdoNylR/bBFsVDusM5QIJHc6g=";
  };

  nativeBuildInputs = [
    unzip
  ];

  installPhase = ''
    runHook preInstall

    cp -r . $out

    # Remove directories phpBB wants to write to,
    # our combiner will add symlinks to mutable paths in their stead.
    # Ensure they are NOT ACCESSIBLE through the web server.
    rm -r $out/store $out/cache $out/files $out/images/avatars/upload $out/config.php

    moveToOutput install/ $installer

    runHook postInstall
  '';

  meta = {
    description = "Flat-forum bulletin board software";
    homepage = "https://www.phpbb.com/";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
