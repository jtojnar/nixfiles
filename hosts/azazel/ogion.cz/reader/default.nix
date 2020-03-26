{ config, lib, pkgs,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "reader.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          path = "ogion.cz/reader";
          config = ''
            location ~* \ (gif|jpg|png) {
              expires 30d;
            }
            location ~ ^/(favicons|thumbnails)/.*$ {
              try_files $uri /data/$uri;
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
  };

  systemd.services.selfoss-update = {
    serviceConfig = {
      ExecStart = "${pkgs.php}/bin/php /var/www/ogion.cz/reader/cliupdate.php";
      User = "nginx";
    };
    startAt = "hourly";
    wantedBy = [ "multi-user.target" ];
  };
}
