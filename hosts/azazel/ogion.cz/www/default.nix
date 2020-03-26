{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          path = "ogion.cz/www";
        };

        "www.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          redirect = "ogion.cz";
        };
      };
    };
  };
}
