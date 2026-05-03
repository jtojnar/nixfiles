{
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP;
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "skirogaining.krk-litvinov.cz" = {
          useACMEHost = "krk-litvinov.cz";
          extraConfig = ''
            root * /var/www/krk-litvinov.cz/skirogaining

            # Redirect to last event.
            redir / /2015-prosinec/cs/

            rewrite /sitemap.txt /sitemap.php

            handle {
              # Try real files first
              try_files {path} @virtual
            }

            handle @virtual {
              # Redirect to default language.
              @lang_redirect path_regexp ^/([^/]+)/?$
              redir @lang_redirect /{re.lang_redirect.1}/cs/

              # Add extra slash to the language route.
              @slash path_regexp ^/([^/]+)/([^/]+)$
              redir @slash /{re.slash.1}/{re.slash.2}/

              # Show main page.
              @main path_regexp ^/([^/]+)/([^/]+)/$
              rewrite @main /{re.main.1}/index.php?page=main&lang={re.main.2}

              # Show other pages.
              @page path_regexp ^/([^/]+)/([^/]+)/(.+)$
              rewrite @page /{re.page.1}/index.php?page={re.page.3}&lang={re.page.2}
            }

            @forbidden_files {
              path /sitemap.php
              path_regexp \.(pg|md|pgc[1-9])$
            }

            respond @forbidden_files 403

            ${enablePHP "skirogaining"}

            file_server
          '';
        };
      };
    };
  };
}
