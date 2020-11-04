{ config, lib, pkgs, ... }:

let
  pqe = pkgs.wrcq;

  port = 5000;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "pqe.rogaining.org" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString port}";
            };
          };
          extraConfig = ''
            if ($host !~* ^pqe\.rogaining\.org$ ) {
                return 444;
            }
          '';
        };
      };
    };
  };

  custom.postgresql.databases = [
    {
      database = "pqe";
      extensions = [
        "plv8"
        "unaccent"
      ];
    }
  ];

  systemd.services = {
    pqe = {
      description = "Prequalified Entrants";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];

      serviceConfig = {
        User = "pqe";
        Group = "pqe";
        ExecStart = "${pkgs.nodejs_latest}/bin/node ${pqe}/index.js";
        WorkingDirectory = pqe;
        Restart = "always";
        RestartSec = "10";
      };

      environment = {
        DATABASE_URL = "socket:/run/postgresql?db=pqe";
        PORT = toString port;
      };
    };
  };

  users = {
    users = {
      pqe = {
        uid = 509;
        group = "pqe";
        isSystemUser = true;
      };
    };

    groups = {
      pqe = {
        gid = 509;
      };
    };
  };
}
