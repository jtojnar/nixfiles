{ config, lib, pkgs, ... }:

let
  pqe = (import ./source { inherit pkgs; }).package;

  port = 5000;
in {
  imports = [
    ../../../../common/modules/postgres.nix
  ];

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
        ExecStart = "${pkgs.nodejs-12_x}/bin/node ${pqe}/lib/node_modules/wrcQ/index.js";
        WorkingDirectory = "${pqe}/lib/node_modules/wrcQ";
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
