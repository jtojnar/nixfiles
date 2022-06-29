{ stdenv
, fetchurl
, lib
, unzip
, php
, common-updater-scripts
, curl
, jq
, writeShellScript
}:

stdenv.mkDerivation rec {
  pname = "phpbb";
  version = "3.3.8";

  outputs = [ "out" "installer" ];

  src = fetchurl {
    url = "https://download.phpbb.com/pub/release/${lib.versions.majorMinor version}/${version}/phpBB-${version}.zip";
    sha256 = "78ekMwajm1/xE3xERirKgMIWEuCWKg+ASOFfvMKOx2w=";
  };

  nativeBuildInputs = [
    unzip
  ];

  buildInputs = [
    php
  ];

  postPatch = ''
    chmod +x bin/phpbbcli.php
  '';

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

  passthru = {
    updateScript = writeShellScript "phpbb-core-updater" ''
      set -e
      export PATH="${lib.makeBinPath [ common-updater-scripts curl jq ]}"
      version="$(curl 'https://version.phpbb.com/phpbb/versions.json' | jq '.stable[.stable | keys | last].current' --raw-output)"
      update-source-version phpbb.core "$version"
    '';
  };

  meta = {
    description = "Flat-forum bulletin board software";
    homepage = "https://www.phpbb.com/";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ jtojnar ];
    platforms = lib.platforms.all;
  };
}
