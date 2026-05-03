{ config, ... }:

{
  imports = [
    ./services/blackbox.nix
    ./services/node.nix
    ./services/php-fpm.nix
    ./services/pushgateway.nix
  ];

  # Dashboard
  services.grafana = {
    enable = true;

    settings = {
      server = {
        domain = "monitor.ogion.cz";
      };
      security = {
        secret_key = "$__file{${config.age.secrets."monitor_grafana.ogion.cz-secret".path}}";
      };
    };

    # TODO: try to make it run without a database. Or at least make it on tmpfs.
    # database.path = "/dev/null";
    # auth.anonymous.enable = true;

    provision = {
      enable = true;
      datasources = {
        settings = {
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:${builtins.toString config.services.prometheus.port}";
              isDefault = true;
              uid = "prometheus";
            }
          ];
        };
      };
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts = {
      "${config.services.grafana.settings.server.domain}" = {
        useACMEHost = "ogion.cz";
        extraConfig = ''
          reverse_proxy 127.0.0.1:${builtins.toString config.services.grafana.settings.server.http_port}
          file_server
        '';
      };
    };
  };

  services.prometheus = {
    enable = true;

    globalConfig = {
      scrape_interval = "15m";
      evaluation_interval = "15m";
    };
  };

  age.secrets = {
    "monitor_grafana.ogion.cz-secret" = {
      owner = config.users.users.grafana.name;
      file = ../../../../secrets/monitor_grafana.ogion.cz-secret.age;
    };
  };
}
