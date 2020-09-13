{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "ostrov-tucnaku.cz" = mkVirtualHost {
          path = "ostrov-tucnaku.cz/www/public";
          acme = true;
          config = ''
            location ~* \.php$ {
              ${enablePHP "ostrov-tucnaku"}
            }

            index index.html index.htm index.php;

            include /var/www/ostrov-tucnaku.cz/www/.nginx.conf;

            client_max_body_size 10M;
          '';
        };

        "www.ostrov-tucnaku.cz" = mkVirtualHost {
          acme = "ostrov-tucnaku.cz";
          redirect = "ostrov-tucnaku.cz";
        };
      };
    };
  };
}
