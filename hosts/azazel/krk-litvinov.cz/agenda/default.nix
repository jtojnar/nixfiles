{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "agenda.krk-litvinov.cz" = mkVirtualHost {
          # acme = "krk-litvinov.cz";
          acme = true;
          path = "krk-litvinov.cz/agenda";
        };
      };
    };
  };
}
