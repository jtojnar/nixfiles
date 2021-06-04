{ config, lib, pkgs,  ... }:
let
  myLib = import ../lib.nix { inherit lib config; };
  inherit (myLib) mkPhpPool;
in {
  imports = [
    ./bag
    ./develop
    ./mechmice
    ./mysql
    ./reader
    ./todo
    ./tools
    ./www
  ];

  security.acme.certs."ogion.cz".extraDomainNames = [
    "www.ogion.cz"
    "bag.ogion.cz"
    # "develop.ogion.cz"
    "mechmice.ogion.cz"
    "mysql.ogion.cz"
    "reader.ogion.cz"
    # "tools.ogion.cz"
  ];

  services = {
    mysql = {
      enable = true;

      ensureDatabases = [
        "mechmice"
      ];
      ensureUsers = [
        { name = "mechmice"; ensurePermissions = { "mechmice.*" = "ALL PRIVILEGES"; }; }
      ];
    };

    phpfpm = rec {
      pools = {
        adminer = mkPhpPool {
          user = "adminer";
          debug = true;
        };
        mechmice = mkPhpPool {
          user = "mechmice";
          phpPackage = pkgs.php74;
          debug = true;
        };
      };
    };
  };

  users = {
    users = {
      jtojnar = {
        extraGroups = [
          "bag"
          "reader"
          "adminer"
          "mechmice"
        ];
      };

      nginx = {
        extraGroups = [
          "bag"
          "reader"
          "adminer"
          "mechmice"
        ];
      };

      bag = { uid = 514; group = "bag"; isSystemUser = true; };
      reader = { uid = 501; group = "reader"; isSystemUser = true; };
      adminer = { uid = 502; group = "adminer"; isSystemUser = true; };
      mechmice = { uid = 503; group = "mechmice"; isSystemUser = true; };
    };

    groups = {
      bag = { gid = 514; };
      reader = { gid = 501; };
      adminer = { gid = 502; };
      mechmice = { gid = 503; };
    };
  };
}
