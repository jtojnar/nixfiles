{
  config,
  lib,
  myLib,
  ...
}:

let
  inherit (myLib) mkVirtualHost enablePHP;
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "upload.fan-club-penguin.cz" = mkVirtualHost {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            root * /var/www/fan-club-penguin.cz/upload
            handle {
              try_files {path} /files{path} /index.php?{query}
              ${enablePHP "fcp"}
              file_server
            }
          '';
        };
      };
    };
  };
}
