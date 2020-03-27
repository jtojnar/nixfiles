{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "entries.krk-litvinov.cz" = mkVirtualHost {
          acme = true;
          # acme = "krk-litvinov.cz";
          path = "krk-litvinov.cz/entries/www";
          config = ''
            index index.php;

            location / {
              try_files $uri $uri/ /index.php;
            }

            sendfile on;
            send_timeout 1024s;

            location ~ \.php {
              fastcgi_split_path_info ^(.+?\.php)(/.*)$;
              ${enablePHP "entries"}
              try_files $uri =404;
            }

            location = /robots.txt { access_log off; log_not_found off; }
            location = /favicon.ico { access_log off; log_not_found off; }
          '';
        };
      };
    };
  };
}
