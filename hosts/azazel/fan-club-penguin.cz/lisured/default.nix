{ config, lib, myLib, ... }:
let
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "lisured.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/lisured";
          config = ''
            index index.php;

            location ~ \.php$ {
              ${enablePHP "fcp"}
            }

            location /app {
              fancyindex on; # Enable directory listing.
              fancyindex_exact_size off; # Use human-readable file sizes.
            }
          '';
        };
      };
    };
  };
}
