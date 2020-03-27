{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "preklady.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/preklady";
          config = ''
            index index.php;

            location / {
              try_files $uri $uri/;
            }

            location /comic {
              try_files $uri $uri/ /comic/index.php;
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
