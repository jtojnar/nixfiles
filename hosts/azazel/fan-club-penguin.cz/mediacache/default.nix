{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "mediacache.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/mediacache";
          config = ''
            location / {
              add_header Access-Control-Allow-Origin *;
              try_files /from-icer.ink/$uri /from-fcp/$uri =404;
            }
          '';
        };
      };
    };
  };
}
