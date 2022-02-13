{ config, lib, myLib, ... }:
let
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "upload.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/upload";
          config = ''
            location / {
              if (!-e $request_filename){
                rewrite ^(.+)$ /files/$1;
              }
              if (!-e $request_filename){
                rewrite ^(.*)$ /index.php break;
              }
            }
          '';
        };
      };
    };
  };
}
