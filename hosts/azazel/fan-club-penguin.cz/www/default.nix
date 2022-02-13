{ config, lib, myLib, ... }:
let
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "fan-club-penguin.cz" = mkVirtualHost {
          acme = true;
          path = "fan-club-penguin.cz/www";
          config = ''
            index index.php index.html index.htm;

            location /index {
              rewrite ^/index\.php$ / redirect;
            }

            location /sitemap {
              rewrite ^/sitemap\.xml$ /sitemap.php;
            }

            location /rss {
              rewrite ^/rss\.xml$ /rss.php;
            }

            location = /search {
              rewrite ^(.*)$ /search.php;
            }

            location / {
              if (!-e $request_filename){
                rewrite ^/(.+)\.html$ /?section=pages&page=$1;
              }
            }

            location /page/ {
              rewrite ^/page/show/(.+)$ /$1.html redirect;
            }

            location /post/ {
              rewrite ^/post/rss$ /rss.xml redirect;
              rewrite ^/post/([^/]+)$ /?section=posts&page=view&id=$1;
              rewrite ^/post/([^/]+)/edit$ /?section=admin&page=postedit&id=$1;
              rewrite ^/post/show/(\d+)$ /post/$1 redirect;
            }

            location /profile/ {
              rewrite ^/profile/show/(\d+)$ /profile/$1 redirect;
              rewrite ^/profile/(\d*)$ /?section=profile&page=view&id=$1;
              rewrite ^/profile/(\d*)/(givestamps|mail)$ /?section=profile&page=$2&id=$1;
            }

            location /user/ {
              rewrite ^/user/(logout|login|edit|register)$ /?section=user&page=$1;
            }

            location = /meeting {
              rewrite ^(.*)$ /?section=meeting&page=list;
            }

            location /meeting {
              rewrite ^/meeting/(new)$ /?section=meeting&page=$1;
              rewrite ^/meeting/(\d*)/(delete|edit)$ /?section=meeting&page=$2&id=$1;
            }

            location = /profile {
              rewrite ^(.*)$ /?section=profile&page=list;
            }

            location = /profile/me {
              rewrite ^(.*)$ /?section=profile&page=me;
            }

            location = /mail {
              rewrite ^(.*)$ /?section=mail&page=list;
            }

            location /mail/ {
              rewrite ^/mail/(sent)$ /?section=mail&page=sent;
              rewrite ^/mail/(\d*)$ /?section=mail&page=view&id=$1;
              rewrite ^/mail/(\d*)/(reply)$ /?section=mail&page=$2&id=$1;
              rewrite ^/mail/show/(\d+)$ /mail/$1 redirect;
            }

            location = /admin {
              rewrite ^(.*)$ /?section=admin&page=panel;
            }

            location /admin/ {
              rewrite ^/admin/(pagenew|pageedit|postnew|posts|pages|twitter|saturdaystamp)$ /?section=admin&page=$1;
              rewrite ^/admin/(highlight|stats)$ /?section=admin&page=$1;
            }

            location ~ \.php$ {
              ${enablePHP "fcp"}
            }
          '';
        };

        "www.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          redirect = "fan-club-penguin.cz";
        };
      };
    };
  };
}
