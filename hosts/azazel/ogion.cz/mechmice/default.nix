{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "mechmice.ogion.cz" = {
          useACMEHost = "ogion.cz";
          extraConfig = ''
            root * /var/www/ogion.cz/mechmice
            file_server
          '';
        };
      };
    };
  };
}
