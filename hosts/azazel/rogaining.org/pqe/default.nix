{ config, lib, pkgs, ... }:

let
  pqe = (import ./source { inherit pkgs; }).package;

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

    postgresql = {
      enable = true;
      package = pkgs.postgresql_11;
      extraPlugins = with pkgs.postgresql_11.pkgs; [
        plv8
      ];
      authentication = lib.mkForce ''
        local all postgres peer
        local sameuser all peer
      '';
      ensureUsers = [
        {
          name = "pqe";
        }
      ];
    };
  };

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

    postgresql = {
      # TODO: allow ensureDatabases to set owner
      postStart = ''
        $PSQL -tAc "SELECT 1 FROM pg_database WHERE datname = 'pqe'" | grep -q 1 || $PSQL -tAc 'CREATE DATABASE "pqe" WITH OWNER = "pqe"'
      '';
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
