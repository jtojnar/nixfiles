{ config, lib, myLib, ... }:
let
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "cyklogaining.tojnar.cz" = mkVirtualHost {
          path = "tojnar.cz/cyklogaining";
          acme = "tojnar.cz";
          config = ''
            index index.php;

            # Do not log automatically scanned resources
            location = /favicon.ico {
              log_not_found off;
              access_log off;
            }

            location = /robots.txt {
              allow all;
              log_not_found off;
              access_log off;
            }

            location / {
              # Old links
              if ($arg_page) {
                return 301 /$arg_page.html;
              }

              try_files $uri /index.php;
            }

            # Home page
            location = /cyklogaining.html {
              return 301 /;
            }

            # Prevent looking at innards.
            location ~ pages/([^\s]*)\.php$ {
              return 301 /$1.html;
            }

            location ~ \.php$ {
              ${enablePHP "cyklogaining"}
            }

            location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
              expires max;
              log_not_found off;
            }
          '';
        };
      };
    };
  };
}
