{
  config,
  lib,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP mkVirtualHost;
in
{
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "rogaining-2019.krk-litvinov.cz" = mkVirtualHost {
          # acme = "krk-litvinov.cz";
          acme = true;
          path = "krk-litvinov.cz/rogaining-2019";
          config = ''
            index index.php;

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
              # This is cool because no php is touched for static content.
              # include the "?$args" part so non-default permalinks doesn't break when using query string
              try_files $uri $uri/ /index.php?$args;
            }

            location ~ \.php$ {
              #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
              fastcgi_intercept_errors on;
              fastcgi_read_timeout 500;
              ${enablePHP "rogaining-2019"}
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
