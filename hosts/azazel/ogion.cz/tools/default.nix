{ config, lib, myLib, ... }:
let
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "tools.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          path = "ogion.cz/tools";
        };
      };
    };
  };
}
