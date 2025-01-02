{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:

let
  inherit (myLib) mkPhpPool;
in
{
  imports = [
    ./www
  ];

  security.acme.certs."mala-zahradka-pro-radost.cz".extraDomainNames = [
    "www.mala-zahradka-pro-radost.cz"
  ];

  users = {
    users = {
      jtojnar = {
        extraGroups = [
          "mzpr"
        ];
      };

      nginx = {
        extraGroups = [
          "mzpr"
        ];
      };

      mzpr = {
        uid = 521;
        group = "mzpr";
        isSystemUser = true;
      };
    };

    groups = {
      mzpr = {
        gid = 521;
      };
    };
  };
}
