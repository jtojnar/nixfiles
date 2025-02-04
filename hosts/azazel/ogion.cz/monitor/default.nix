{ config, myLib, ... }:

let
  inherit (myLib) mkVirtualHost;
in
{
  imports = [
    ./services/blackbox.nix
    ./services/node.nix
    ./services/pushgateway.nix
  ];

  # Dashboard
  services.grafana = {
    enable = true;

    settings = {
      server = {
        domain = "monitor.ogion.cz";
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

  services.nginx = {
    enable = true;

    virtualHosts = {
      "${config.services.grafana.settings.server.domain}" = mkVirtualHost {
        acme = "ogion.cz";
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString config.services.grafana.settings.server.http_port}";
            proxyWebsockets = true;
            extraConfig = ''
              # https://github.com/grafana/grafana/issues/45117
              proxy_set_header Host $host;
            '';
          };
        };
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
}
