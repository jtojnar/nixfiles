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
    nginx = {
      enable = true;

      virtualHosts = {
        "preklady.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/preklady";
          config = ''
            index index.php;

            location /comic {
              try_files $uri $uri/ /comic/index.php;
            }

            location /comic/data/prelozit {
              fancyindex on; # Enable directory listing.
              fancyindex_exact_size off; # Use human-readable file sizes.
            }

            location /library {
              try_files $uri $uri /library/index.php;
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
