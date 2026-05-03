{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "http://develop.ogion.cz" = {
          extraConfig = ''
            root * /var/www/ogion.cz/develop
            file_server
          '';
        };
      };
    };
  };
}
