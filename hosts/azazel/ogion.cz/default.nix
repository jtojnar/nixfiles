{ config, lib, pkgs,  ... }:
let
  myLib = import ../lib.nix { inherit lib config; };
  inherit (myLib) mkCert mkPhpPool;
in {
  imports = [
    ./develop
    ./mechmice
    ./mysql
    ./reader
    ./todo
    ./tools
    ./www
  ];

  security.acme.certs = {
    "ogion.cz" = mkCert {
      domains = [
        "www.ogion.cz"
        # "develop.ogion.cz"
        "mechmice.ogion.cz"
        "mysql.ogion.cz"
        "reader.ogion.cz"
        # "tools.ogion.cz"
      ];
    };
  };

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
          debug = true;
        };
      };
    };
  };

  users = {
    users = {
      jtojnar = {
        extraGroups = [
          "reader"
          "adminer"
          "mechmice"
        ];
      };

      nginx = {
        extraGroups = [
          "reader"
          "adminer"
          "mechmice"
        ];
      };

      reader = { uid = 501; group = "reader"; isSystemUser = true; };
      adminer = { uid = 502; group = "adminer"; isSystemUser = true; };
      mechmice = { uid = 503; group = "mechmice"; isSystemUser = true; };
    };

    groups = {
      reader = { gid = 501; };
      adminer = { gid = 502; };
      mechmice = { gid = 503; };
    };
  };
}
