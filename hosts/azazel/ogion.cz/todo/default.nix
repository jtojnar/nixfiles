{ config, ... }:

{
  services = {
    vikunja = {
      enable = true;

      database = {
        type = "postgres";
        host = "/run/postgresql";
      };

      settings = {
          service.enableregistration = false;
      };

      frontendScheme = "https";
      frontendHostname = "todo.ogion.cz";
    };

    nginx = {
      enable = true;

      virtualHosts = {
        "todo.ogion.cz" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString config.services.vikunja.port}";
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
}
