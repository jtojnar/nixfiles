{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "saman.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            root * /var/www/fan-club-penguin.cz/saman
            file_server
          '';
        };
      };
    };
  };
}
