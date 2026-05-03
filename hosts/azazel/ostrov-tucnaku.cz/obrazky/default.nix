{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "obrazky.ostrov-tucnaku.cz" = {
          useACMEHost = "ostrov-tucnaku.cz";
          extraConfig = ''
            root * /var/www/ostrov-tucnaku.cz/obrazky

            static path_regexp static \.(css|js|gif|jpe?g|png)$

            header @static {
                Cache-Control "public, max-age=2592000, must-revalidate, proxy-revalidate"
                Pragma "public"
            }

            file_server
          '';
        };
      };
    };
  };
}
