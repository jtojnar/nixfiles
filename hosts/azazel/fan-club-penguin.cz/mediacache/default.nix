{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "mediacache.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          config = ''
            root * /var/www/fan-club-penguin.cz/mediacache

            handle / {
              header {
                Access-Control-Allow-Origin *
              }

              try_files /from-icer.ink{path} /from-fcp{path} =404
              file_server
            }
          '';
        };
      };
    };
  };
}
