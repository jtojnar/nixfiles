{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "jitsucards.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            root * /var/www/fan-club-penguin.cz/jitsucards
            file_server
          '';
        };
      };
    };
  };
}
