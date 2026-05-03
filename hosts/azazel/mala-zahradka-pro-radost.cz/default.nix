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

  # TODO: generate cert
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

      caddy = {
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
