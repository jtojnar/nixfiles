{ config, pkgs, ... }:

let
  # Grafana dashboard with overview of node_exporter.
  # https://grafana.com/grafana/dashboards/13978
  nodeDashbord = pkgs.fetchurl {
    name = "node-dashboard";
    url = "https://grafana.com/api/dashboards/13978/revisions/2/download";
    hash = "sha256-Z7WzUf5SdR/267FuEQaAfmnM7UW90YVnJSF61y2q/xQ=";
    recursiveHash = true;
    postFetch = ''
      mv "$out" temp
      mkdir -p "$out"
      mv temp "$out/node-dashboard.json";
    '';
  };
  # https://grafana.com/grafana/dashboards/1860
  nodeDashbordFull = pkgs.fetchurl {
    name = "node-dashboard";
    url = "https://grafana.com/api/dashboards/1860/revisions/31/download";
    hash = "sha256-xuFX0QTFt6Xjdv412bk5+hiGvCTH5NXFUftuazb+M0Q=";
    recursiveHash = true;
    postFetch = ''
      mv "$out" temp
      mkdir -p "$out"
      mv temp "$out/node-dashboard-full.json";
    '';
  };
in
{
  services.grafana = {
    provision = {
      dashboards = {
        settings = {
          providers = [
            {
              name = "Node info full";
              options.path = nodeDashbordFull;
            }
            {
              name = "Node info";
              options.path = nodeDashbord;
            }
          ];
        };
      };
    };
  };

  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "disable-defaults"
          "cpu"
          "diskstats"
          "filesystem"
          "meminfo"
          "netdev"
          "systemd"
        ];
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.node.port}"
            ];
            labels = {
              alias = "localhost";
            };
          }
        ];
      }
    ];
  };
}
