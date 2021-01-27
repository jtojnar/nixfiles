{ lib
, fetchFromGitHub
, naerskUnstable
, pkg-config
, perl
, openssl
}:

let
  version = "unstable-2020-04-22";

  sources = fetchFromGitHub {
    owner = "ActivityWatch";
    repo = "activitywatch";
    rev = "d39648092fa8fa1adff0809b2f9bccdde99537af";
    sha256 = "3Sz+Vjn20cfD5UnR3pvevX+icU8l//uNMOkfnRp/+NU=";
    fetchSubmodules = true;
  };

in

{
  aw-server-rust = naerskUnstable.buildPackage {
    pname = "aw-server-rust";
    inherit version;

    root = "${sources}/aw-server-rust";

    nativeBuildInputs = [
      pkg-config
      perl
    ];

    buildInputs = [
      openssl
    ];

    meta = with lib; {
      description = "Cross-platform, extensible, privacy-focused, free and open-source automated time tracker";
      homepage = "https://activitywatch.net/";
      maintainers = with maintainers; [ jtojnar ];
      platforms = platforms.linux;
      license = licenses.mpl20;
    };
  };
}
