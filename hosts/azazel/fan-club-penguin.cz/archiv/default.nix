{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "archiv.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/archiv";
          config = ''
            index index.php;

            location / {
              try_files $uri $uri/ /index.php;
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
