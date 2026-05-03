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
        "cyklogaining.tojnar.cz" = {
          useACMEHost = "tojnar.cz";
          extraConfig = ''
            root * /var/www/tojnar.cz/cyklogaining

            # Old links: ?page=foo → /foo.html
            @oldlinks query page=*
            redir @oldlinks /{query.page}.html permanent

            # Old home redirect
            redir /cyklogaining.html / permanent

            # Prevent direct access to internal PHP pages
            # /pages/foo.php → /foo.html
            @pages path_regexp pages ^/pages/([^\s]+)\.php$
            redir @pages /{re.pages.1}.html permanent

            ${enablePHP "cyklogaining"}
          '';
        };
      };
    };
  };
}
