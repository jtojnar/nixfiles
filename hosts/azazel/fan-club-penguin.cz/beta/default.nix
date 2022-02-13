{ config, lib, myLib, ... }:
let
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "beta.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/@beta/www";
          config = ''
            index index.php;

            if ($cookie_beta != "1") {
              return 401;
            }

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
