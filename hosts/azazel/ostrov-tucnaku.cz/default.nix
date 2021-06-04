{ config, lib, pkgs,  ... }:
let
  myLib = import ../lib.nix { inherit lib config; };
  inherit (myLib) mkPhpPool;
in {
  imports = [
    ./obrazky
    ./www
  ];

  security.acme.certs."ostrov-tucnaku.cz".extraDomainNames = [
    "obrazky.ostrov-tucnaku.cz"
  ];

  services = {
    mysql = {
      enable = true;

      ensureDatabases = [
        "ostrov-tucnaku"
      ];
      ensureUsers = [
        { name = "ostrov-tucnaku"; ensurePermissions = { "\\`ostrov-tucnaku\\`.*" = "ALL PRIVILEGES"; }; }
      ];
    };

    phpfpm = rec {
      pools = {
        ostrov-tucnaku = mkPhpPool {
          user = "ostrov-tucnaku";
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
          "ostrov-tucnaku"
        ];
      };

      nginx = {
        extraGroups = [
          "ostrov-tucnaku"
        ];
      };

      ostrov-tucnaku = { uid = 506; group = "ostrov-tucnaku"; isSystemUser = true; };
    };

    groups = {
      ostrov-tucnaku = { gid = 506; };
    };
  };
}
