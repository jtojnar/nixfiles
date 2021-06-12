{ config, lib, pkgs, ... }:

let
  port = 5001;

  inherit (pkgs) vikunja-frontend vikunja-api;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "todo.ogion.cz" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              root = vikunja-frontend;
              tryFiles = "$uri $uri/ /";
              index = "index.html";
            };
            "~* ^/(api|dav|\\.well-known)/" = {
              proxyPass = "http://localhost:${toString port}";
            };
          };
          extraConfig = ''
            if ($host !~* ^todo\.ogion\.cz$ ) {
                return 444;
            }
          '';
        };
      };
    };
  };

  custom.postgresql.databases = [
    {
      database = "vikunja";
    }
  ];

  systemd.services = {
    vikunja = {
      description = "Vikunja API";
      wantedBy = [ "multi-user.target" ];
      after = [ "syslog.target" "network.target" "postgresql.service" ];

      serviceConfig = {
        User = "vikunja";
        Group = "vikunja";
        ExecStart = "${vikunja-api}/bin/vikunja";
        WorkingDirectory = "${vikunja-api}";
        Restart = "always";
        RestartSec = "10";
      };

      environment = {
        VIKUNJA_DATABASE_TYPE = "postgres";
        VIKUNJA_DATABASE_HOST = "/run/postgresql";
        VIKUNJA_SERVICE_INTERFACE = ":${toString port}";
        VIKUNJA_SERVICE_FRONTENDURL = "https://todo.ogion.cz";
        VIKUNJA_SERVICE_ENABLEREGISTRATION = "false";
      };
    };
  };

  users = {
    users = {
      vikunja = {
        uid = 510;
        group = "vikunja";
        isSystemUser = true;
      };
    };

    groups = {
      vikunja = {
        gid = 510;
      };
    };
  };
}
