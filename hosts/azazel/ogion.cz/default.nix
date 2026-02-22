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
    ./auth
    ./bag
    ./develop
    ./code
    ./mechmice
    ./monitor
    ./mysql
    ./pad
    ./reader
    ./temp
    ./todo
    ./tools
    ./www
  ];

  security.acme.certs."ogion.cz".extraDomainNames = [
    "www.ogion.cz"
    "auth.ogion.cz"
    "bag.ogion.cz"
    "code.ogion.cz"
    "mechmice.ogion.cz"
    "monitor.ogion.cz"
    "mysql.ogion.cz"
    "pad.ogion.cz"
    "reader.ogion.cz"
    "temp.ogion.cz"
    "tools.ogion.cz"
  ];

  services = {
    mysql = {
      enable = true;

      ensureDatabases = [
        "mechmice"
      ];
      ensureUsers = [
        {
          name = "mechmice";
          ensurePermissions = {
            "mechmice.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    phpfpm = rec {
      pools = {
        adminer = mkPhpPool {
          user = "adminer";
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
          "pad"
          "reader"
          "adminer"
          "mechmice"
        ];
      };

      bag = {
        uid = 514;
        group = "bag";
        isSystemUser = true;
      };
      reader = {
        uid = 501;
        group = "reader";
        isSystemUser = true;
      };
      adminer = {
        uid = 502;
        group = "adminer";
        isSystemUser = true;
      };
      mechmice = {
        uid = 503;
        group = "mechmice";
        isSystemUser = true;
      };
      pad = {
        uid = 523;
        group = "pad";
        isSystemUser = true;
      };
      tools = {
        uid = 519;
        group = "tools";
        isSystemUser = true;
      };
    };

    groups = {
      bag = {
        gid = 514;
      };
      reader = {
        gid = 501;
      };
      adminer = {
        gid = 502;
      };
      mechmice = {
        gid = 503;
      };
      pad = {
        gid = 523;
      };
      tools = {
        gid = 519;
      };
    };
  };
}
