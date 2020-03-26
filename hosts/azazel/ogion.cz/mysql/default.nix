{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "mysql.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          path = "fan-club-penguin.cz/mysql";
          config = ''
            index index.php;

            location / {
              index index.php;
              try_files $uri $uri/ /index.php?$args;
            }

            location ~ \.php$ {
              ${enablePHP "adminer"}
              fastcgi_read_timeout 500;
            }
          '';
        };
      };
    };
  };
}
