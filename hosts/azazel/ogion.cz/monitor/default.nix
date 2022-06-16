{ config, lib, myLib, pkgs, ... }:

let
  inherit (myLib) mkVirtualHost;

  # Grafana dashboard with overview of HTTP status codes of various services.
  # https://grafana.com/grafana/dashboards/13659
  blackboxDashbord = pkgs.fetchurl {
    name = "blackbox-dashboard";
    url = "https://grafana.com/api/dashboards/13659/revisions/1/download";
    sha256 = "hPuo66GErLhUu5XiCBegastj6DUp8A3zkRlOaXX044U=";
    recursiveHash = true;
    postFetch = ''
      # Needs to match the Prometheus datasource uid.
      substituteInPlace "$out" --replace ''\'''${DS_PROMETHEUS}' 'prometheus'
      mv "$out" temp
      mkdir -p "$out"
      mv temp "$out/blackbox-dashboard.json";
    '';
  };

  mkBlackboxProbe =
    module:
    targets:
    {
      job_name = "blackbox-${module}";
      metrics_path = "/probe";
      # TODO: Increase this interval. The dashboard does not seem to like anything longer –
      # it is only able to see current time series and for some reason the events have the duration of 4m45s.
      scrape_interval = "4m30s";
      params = {
        module = [ module ];
      };
      static_configs = [
        {
          inherit targets;
        }
      ];
      # ???
      relabel_configs = [
        {
          source_labels = [ "__address__" ];
          target_label = "__param_target";
        }
        {
          source_labels = [ "__param_target" ];
          target_label = "instance";
        }
        {
          target_label = "__address__";
          replacement = "localhost:${builtins.toString config.services.prometheus.exporters.blackbox.port}";
        }
      ];
    };
in
{
  # Dashboard
  services.grafana = {
    enable = true;
    domain = "monitor.ogion.cz";

    # TODO: try to make it run without a database. Or at least make it on tmpfs.
    # database.path = "/dev/null";
    # auth.anonymous.enable = true;

    provision = {
      enable = true;
      datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:${builtins.toString config.services.prometheus.port}";
          isDefault = true;
          uid = "prometheus";
        }
      ];

      dashboards = [
        {
          name = "HTTP status";
          options.path = blackboxDashbord;
        }
      ];
    };
  };

  services.nginx = {
    enable = true;

    virtualHosts = {
      "${config.services.grafana.domain}" = mkVirtualHost {
        acme = "ogion.cz";
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString config.services.grafana.port}";
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

    exporters = {
      blackbox = {
        enable = true;
        configFile = pkgs.writeText "blackbox-exporter.yaml" (builtins.toJSON {
          modules = {
            https_success = {
              prober = "http";
              tcp = {
                tls = true;
              };
              http = {
                headers = {
                  User-Agent = "blackbox-exporter";
                  # For https://beta.fan-club-penguin.cz
                  Cookie = "beta=1";
                };
              };
            };
          };
        });
      };
    };

    scrapeConfigs = [
      (
        let
          pathsToIgnore = [
            # No index.html
            "upload.fan-club-penguin.cz"
            "saman.fan-club-penguin.cz"
            "obrazky.ostrov-tucnaku.cz"
            "tools.ogion.cz"
            "temp.ogion.cz"
            "mediacache.fan-club-penguin.cz"
            "kafu.fan-club-penguin.cz"
            "cdn.fan-club-penguin.cz"
            # Requires authentication
            "tgwh.ostrov-tucnaku.cz"
          ];

          pathsToMonitor = {
            # No index.html in root.
            "preklady.fan-club-penguin.cz" = [
              "/comic/"
            ];
          }
          // (
            lib.genAttrs pathsToIgnore (_: [ ])
          );

          checkedUrls =
            builtins.concatLists (
              lib.mapAttrsToList
                (
                  hostName:
                  vhost:
                  let
                    onlySSL = vhost.onlySSL || vhost.enableSSL;
                    hasSSL = onlySSL || vhost.addSSL || vhost.forceSSL;
                  in
                  builtins.map (path: "http${lib.optionalString hasSSL "s"}://${hostName}${path}") (pathsToMonitor.${hostName} or [ "/" ])
                )
                config.services.nginx.virtualHosts
            );
        in
        mkBlackboxProbe "https_success" checkedUrls
      )
    ];
  };

}
