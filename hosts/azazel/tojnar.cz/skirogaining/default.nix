{ config, lib,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "skirogaining.tojnar.cz" = mkVirtualHost {
          acme = "tojnar.cz";
          config = ''
            location / {
              rewrite ^/Skirogaining_2010/(.*)$ https://skirogaining.krk-litvinov.cz/2010/$1 permanent;
              rewrite ^/(.*)$ https://skirogaining.krk-litvinov.cz/2012/$1 permanent;
            }
          '';
        };
      };
    };
  };
}
