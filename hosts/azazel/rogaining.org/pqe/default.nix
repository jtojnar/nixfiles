{
  config,
  lib,
  pkgs,
  ...
}:

let
  pqe = pkgs.wrcq;

  port = 5000;
in
{
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
      extraUsers = [
        "tojnar"
        "jtojnar"
      ];
    }
  ];

  systemd.packages = [
    pqe
  ];

  systemd.services = {
    pqe = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "pqe";
        Group = "pqe";
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
