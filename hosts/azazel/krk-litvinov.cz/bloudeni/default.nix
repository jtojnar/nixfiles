{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "bloudeni.krk-litvinov.cz" = mkVirtualHost {
          # acme = "krk-litvinov.cz";
          path = "krk-litvinov.cz/bloudeni";
        };
      };
    };
  };
}
