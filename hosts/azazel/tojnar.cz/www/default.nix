{
  config,
  lib,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP mkVirtualHost;

  self = config.services.nginx.virtualHosts."www.tojnar.cz";
in
{
  services = {
    nginx = {
      enable = true;

      commonHttpConfig = ''
        map $arg_page $tojnar_page_redirect {
          cestopisy /cestopisy/;
          residence /kontakt.html;
          laponsko_2009 /cestopisy/laponsko_2009/;
          akce_ob /akce_ob/;
          akce_litvinov /akce_litvinov/;
          ~^clanky(/clanky)?$ /literatura/;
          ~^clanky/(.+)$ /literatura/$1.html;
          cestopisy/slovensko_2008/gerlach_2008 /cestopisy/slovensko_2008/;
          akce_litvinov/Flajsky_Kanal/flajsky_kanal /akce_litvinov/flajsky-kanal/;
          ~^(.+/)?(.+)/\2$ /$1$2/;
          krk /krk/;
          ## Generic fallback
          ~^(.*)/$ /$1/;
          ~^(.*)$ /$1.html;
        }
      '';

      virtualHosts = {
        "tojnar.cz" = mkVirtualHost {
          acme = true;
          redirect = "www.tojnar.cz";
        };

        "www.tojnar.cz" = mkVirtualHost {
          path = "tojnar.cz/www";
          acme = "tojnar.cz";
          config = ''
            index index.html index.php;
            recursive_error_pages on;

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
              root ${self.root}/public;
              error_page 403 404 = @old;

              # Canonization
              if ($tojnar_page_redirect) {
                set $args "";
                rewrite .* $tojnar_page_redirect redirect;
              }
            }

            location @old {
              root ${self.root}/old;
              error_page 403 404 = @old_pages;
            }

            location @old_pages {
              root ${self.root}/old/pages;
              error_page 403 404 = @fallback;
              # try_files $uri $uri/index.php @fallback;
            }

            location @fallback {
              root ${self.root}/old;
              error_page 403 404 = /old/index.php;
            }

            location /pages {
              rewrite ^/pages(/.*)$ $1 redirect;
            }

            # Prevent looking at innards.
            location ~ pages/([^\s]*)\.php$ {
              return 301 /$1.html;
            }

            location /cestopisy/island_2011 {
              root ${self.root}/old/cestopisy/island_2011;
              rewrite ^/cestopisy/island_2011$ /cestopisy/island_2011/;
              location ~ ^/cestopisy/island_2011(/[^\s]*)$ {
                try_files $1 /old/cestopisy/island_2011/index.php;
              }
            }

            location /cestopisy/peru_2014 {
              root ${self.root}/old/cestopisy/peru_2014;
              rewrite ^/cestopisy/peru_2014$ /cestopisy/peru_2014/;
              location ~ ^/cestopisy/peru_2014(/[^\s]*)$ {
                try_files $1 /old/cestopisy/peru_2014/index.php;
              }
            }

            location /cestopisy/svalbard_2013 {
              root ${self.root}/old/cestopisy/svalbard_2013;
              rewrite ^/cestopisy/svalbard_2013$ /cestopisy/svalbard_2013/;
              location ~ ^/cestopisy/svalbard_2013(/[^\s]*)$ {
                try_files $1 /old/cestopisy/svalbard_2013/index.php;
              }
            }

            location /krk {
              rewrite ^/krk(.*)$ https://krk.tojnar.cz$1 permanent;
            }

            location ~ \.php$ {
              if ($request_uri ~ ^([^\s]*/)(main|mainkrk|index|print)\.php((?:\?.+)?)$) {
                return 302 $1$3;
              }
              ${enablePHP "tojnar-cz"}
            }
          '';
        };
      };
    };
  };
}
