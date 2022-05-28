{ config, lib, pkgs, myLib, ... }:
let
  inherit (myLib) mkPhpPool;
in {
  imports = [
    ./obrazky
    ./tgwh
    ./www
  ];

  security.acme.certs."ostrov-tucnaku.cz".extraDomainNames = [
    "obrazky.ostrov-tucnaku.cz"
    "tgwh.ostrov-tucnaku.cz"
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

          phpOptions = ''
            ; Set up $_ENV superglobal.
            ; http://php.net/request-order
            variables_order = "EGPCS"
          '';
          settings = {
            # Accept settings from the systemd service.
            clear_env = false;
          };
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
