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
        "skirogaining.krk-litvinov.cz" = mkVirtualHost {
          path = "krk-litvinov.cz/skirogaining";
          acme = true;
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

            location = / {
              # Redirect to last event.
              return 302 /2015-prosinec/cs/;
            }

            location / {
              rewrite ^/sitemap.txt$ /sitemap.php last;
              try_files $uri @virtual_page;
            }

            location @virtual_page {
              # Redirect to default language.
              rewrite ^/([^/]+)/?$ /$1/cs/ redirect;
              # Add extra slash to the language route.
              rewrite ^/([^/]+)/([^/]+)$ /$1/$2/ redirect;
              # Show main page.
              rewrite ^/([^/]+)/([^/]+)/$ /$1/index.php?page=main&lang=$2 last;
              # Show other pages.
              rewrite ^/([^/]+)/([^/]+)/(.+)$ /$1/index.php?page=$3&lang=$2 last;
            }

            location = /sitemap.php {
              return 403;
            }

            location ~* \.(pg|md|pgc[1-9])$ {
              return 403;
            }

            location ~ \.php$ {
              #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
              fastcgi_intercept_errors on;
              fastcgi_read_timeout 500;
              ${enablePHP "skirogaining"}
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
