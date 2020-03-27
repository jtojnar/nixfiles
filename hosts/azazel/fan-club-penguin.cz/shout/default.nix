{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "shout.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/shout";
          config = ''
            index index.php;

            location ~ \.php$ {
              ${enablePHP "fcp"}
            }
          '';
        };
      };
    };
  };
}
