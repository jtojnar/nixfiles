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

      commonHttpConfig = ''
        map $arg_lang $krk_lang_prefix {
          en "/en";
          de "/de";
          default "";
        }

        map $arg_lang $krk_lang_prefix_solo {
          en "/en/";
          de "/de/";
          cs "/";
        }

        map $arg_page $krk_page_redirect {
          krk_default $krk_lang_prefix/;
          mcr_2009 $krk_lang_prefix/mcr_2009/;
          clanky $krk_lang_prefix/clanky/;
          ~^(.+/)?(.+)/\2$ $krk_lang_prefix/$1$2/;
          ## Generic fallback
          ~^(.*)/$ $krk_lang_prefix/$1/;
          ~^(.*)$ $krk_lang_prefix/$1.html;
        }
      '';

      virtualHosts = {
        "krk.tojnar.cz" = mkVirtualHost {
          path = "tojnar.cz/krk";
          acme = "tojnar.cz";
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
              # Canonization
              rewrite ^/cs(?:/(.*))?$ /$1 redirect;
              rewrite ^/(en|de)$ /$1/ redirect;
              if ($krk_page_redirect) {
                set $args "";
                rewrite .* $krk_page_redirect redirect;
              }
              if ($krk_lang_prefix_solo) {
                set $args "";
                rewrite ^(?:/(.*)?)$ $krk_lang_prefix_solo$1 redirect;
              }

              try_files
                $uri
                $uri/
                /pages$uri
                /index.php;

              location /ms_2010_nz {
                rewrite ^/ms_2010_nz/(.*)\.html$ /ms_2010_nz/index.php?page=$1;
              }

              location /prebor2010 {
                rewrite ^/prebor2010/(.*)\.html$ /prebor2010/index.php?page=$1;
              }

              location /lob2011 {
                error_page 404 /lob2011/index.php?page=error/404&lang=cs;
                error_page 403 /lob2011/index.php?page=error/403&lang=cs;
                rewrite ^/lob2011/cs/(.+)/$ /lob2011/index.php?page=$1&lang=cs last;
                rewrite ^/lob2011/en/(.+)/$ /lob2011/index.php?page=$1&lang=en last;
                rewrite ^/lob2011/de/(.+)/$ /lob2011/index.php?page=$1&lang=de last;
                rewrite ^/lob2011/cs$ /lob2011/cs/ redirect;
                rewrite ^/lob2011/en$ /lob2011/en/ redirect;
                rewrite ^/lob2011/de$ /lob2011/de/ redirect;
                rewrite ^/lob2011/cs/$ /lob2011/index.php?page=main&lang=cs last;
                rewrite ^/lob2011/en/$ /lob2011/index.php?page=main&lang=en last;
                rewrite ^/lob2011/de/$ /lob2011/index.php?page=main&lang=de last;
                rewrite ^/sitemap\.txt$ /lob2011/sitemap.php last;
                rewrite ^/lob2011/cs/(.+)$ /lob2011/index.php?page=$1&lang=cs last;
                rewrite ^/lob2011/en/(.+)$ /lob2011/index.php?page=$1&lang=en last;
                rewrite ^/lob2011/de/(.+)$ /lob2011/index.php?page=$1&lang=de last;

                location ~ (.*)\.(pg|pgc[1-9]|mn)$ {
                  internal;
                }
              }
            }

            location /pages {
              rewrite ^/pages(/.*)$ $1 redirect;
            }

            # Prevent looking at innards.
            location ~ pages/([^\s]*)\.php$ {
              return 301 /$1.html;
            }

            location ~ \.php$ {
              if ($request_uri ~ ^([^\s]*/)(mainkrk|index|print)\.php((?:\?.+)?)$) {
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
