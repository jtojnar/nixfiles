{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "temp.ogion.cz" = {
          useACMEHost = "ogion.cz";
          extraConfig = ''
            root * /var/www/ogion.cz/temp
            file_server
          '';
        };
      };
    };
  };
}
