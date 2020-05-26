{ config, lib, pkgs,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkPhpPool mkVirtualHost;

  settings = {
    username = "jtojnar";
    password = "$2y$10$vLbhYNg4KvHQOCggf1rrx.pVcALVYG.zEkYuBMXWEqOE84u/wOSzS";
    auto_mark_as_read = "1";
    share = "p";
    homepage = "unread";
    # TZ = "Europe/Prague";
    TZ = "UTC";
    datadir = "/var/www/ogion.cz/reader/data";
    logger_destination = "file:php://stderr";
    logger_level = "DEBUG";
    base_url = "https://reader.ogion.cz/";
    items_lifetime = "9999";
    # selfoss_scroll_to_article_header = "0";
  };

  settingsEnv = lib.mapAttrs' (name: value: lib.nameValuePair "selfoss_${name}" value) settings;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "reader.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          root = pkgs.selfoss;
          config = ''
            location ~* \ (gif|jpg|png) {
              expires 30d;
            }
            location ~ ^/(favicons|thumbnails)/.*$ {
              root ${settings.datadir};
            }
            location ~* ^/(data\/logs|data\/sqlite|config\.ini|\.ht) {
              deny all;
            }
            location / {
              index index.php;
              try_files $uri /public/$uri /index.php$is_args$args;
            }
            location ~ \.php$ {
              ${enablePHP "reader"}
            }
          '';
        };
      };
    };

    phpfpm = rec {
      pools = {
        reader = mkPhpPool {
          user = "reader";
          debug = true;
          phpOptions = ''
            ; Set up $_ENV superglobal.
            ; http://php.net/request-order
            variables_order = "EGPCS"
          '';
          settings = {
            # Accept settings from the systemd service.
            clear_env = false;
          };
        };
      };
    };
  };

  # I was not able to pass the variables through services.phpfpm.pools.reader.phpEnv:
  # https://github.com/NixOS/nixpkgs/issues/79469#issuecomment-631461513
  systemd.services.phpfpm-reader.environment = settingsEnv;

  systemd.services.selfoss-update = {
    serviceConfig = {
      ExecStart = "${pkgs.php}/bin/php ${pkgs.selfoss}/cliupdate.php";
      User = "reader";
    };
    environment = settingsEnv;
    startAt = "hourly";
    wantedBy = [ "multi-user.target" ];
  };
}
