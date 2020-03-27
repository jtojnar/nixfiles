{ config, lib, pkgs,  ... }:
let
  myLib = import ../lib.nix { inherit lib config; };
  inherit (myLib) mkCert mkPhpPool;
in {
  imports = [
    ./obrazky
    ./www
  ];

  security.acme.certs = {
    "ostrov-tucnaku.cz" = mkCert {
      user = "ostrov-tucnaku";
      domains = [ "obrazky.ostrov-tucnaku.cz" ];
    };
  };

  services = {
    mysql = {
      enable = true;
    };

    phpfpm = rec {
      pools = {
        ostrov-tucnaku = mkPhpPool {
          user = "ostrov-tucnaku";
          debug = true;
        };
      };
    };
  };

  users = {
    users = {
      jtojnar = {
        extraGroups = [
          "ostrov-tucnaku"
        ];
      };

      nginx = {
        extraGroups = [
          "ostrov-tucnaku"
        ];
      };

      ostrov-tucnaku = { uid = 506; group = "ostrov-tucnaku"; isSystemUser = true; };
    };

    groups = {
      ostrov-tucnaku = { gid = 506; };
    };
  };
}
