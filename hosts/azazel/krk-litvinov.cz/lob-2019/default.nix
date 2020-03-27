{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "lob-2019.krk-litvinov.cz" = mkVirtualHost {
          # acme = "krk-litvinov.cz";
          acme = true;
          path = "krk-litvinov.cz/lob-2019";
        };
      };
    };
  };
}
