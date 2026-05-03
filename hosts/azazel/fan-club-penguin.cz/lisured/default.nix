{
  config,
  lib,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP mkVirtualHost;
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "lisured.fan-club-penguin.cz" = mkVirtualHost {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            root * /var/www/fan-club-penguin.cz/lisured
            file_server
            ${enablePHP "fcp"}

            handle /app/* {
              file_server browse
            }
          '';
        };
      };
    };
  };
}
