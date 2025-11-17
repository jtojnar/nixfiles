{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Grafana dashboard with overview of PHP-FPM pools.
  # https://grafana.com/grafana/dashboards/4912-kubernetes-php-fpm
  phpFpmDashboard = pkgs.fetchurl {
    name = "kubernetes-php-fpm";
    url = "https://grafana.com/api/dashboards/4912/revisions/1/download";
    hash = "sha256-ZsiAkT7nzYLHs+zHr/ooppnWsy/bTjBSSU0Oy/cVynI=";
    recursiveHash = true;
    postFetch = ''
      # Needs to match the Prometheus datasource uid.
      substituteInPlace "$out" --replace-fail ''\'''${DS_PROMETHEUS}' 'prometheus'
      mv "$out" temp
      mkdir -p "$out"
      mv temp "$out/kubernetes-php-fpm.json";
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
              name = "php-fpm status";
              options.path = phpFpmDashboard;
            }
          ];
        };
      };
    };
  };

  systemd.services."prometheus-php-fpm-exporter".serviceConfig = {
    RestrictAddressFamilies = [
      # Defaults to IP only
      "AF_UNIX"
    ];
  };

  services.prometheus = {
    exporters = {
      php-fpm = {
        enable = true;
        environmentFile = pkgs.writeTextFile {
          name = "prometheus-php-fpm-exporter.env";
          text =
            let
              poolNames = builtins.attrNames config.services.phpfpm.pools;
              scrapeUris = lib.concatMapStringsSep "," (
                name: "unix:///run/phpfpm/${name}.sock;/status"
              ) poolNames;
            in
            ''
              PHP_FPM_SCRAPE_URI="${scrapeUris}"
            '';
        };
      };
    };

    scrapeConfigs = [
      {
        job_name = "php-fpm";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [
              "localhost:${toString config.services.prometheus.exporters.php-fpm.port}"
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
