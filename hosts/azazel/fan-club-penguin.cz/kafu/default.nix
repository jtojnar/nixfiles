{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "kafu.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            root * /var/www/fan-club-penguin.cz/kafu
            file_server
          '';
        };
      };
    };
  };
}
