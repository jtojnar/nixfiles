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

    caddy = {
      enable = true;

      virtualHosts = {
        "todo.ogion.cz" = {
          useACMEHost = "ogion.cz";
          extraConfig = ''
            reverse_proxy localhost:${toString config.services.vikunja.port}
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
