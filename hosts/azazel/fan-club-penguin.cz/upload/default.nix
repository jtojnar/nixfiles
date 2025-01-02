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
    nginx = {
      enable = true;

      virtualHosts = {
        "upload.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/upload";
          config = ''
            location / {
              try_files "$uri" "/files/$uri" /index.php;
            }

            location ~ \.php$ {
              ${enablePHP "fcp"}
            }
          '';
        };
      };
    };
  };
}
