{ config, lib, pkgs,  ... }:
let
  myLib = import ../lib.nix { inherit lib config; };
  inherit (myLib) mkCert mkPhpPool;
in {
  imports = [
    ./archiv
    ./beta
    ./cdn
    ./forum
    ./lisured
    ./mediacache
    ./preklady
    ./provider
    ./shout
    ./upload
    ./www
  ];

  security.acme.certs = {
    "fan-club-penguin.cz" = mkCert {
      user = "fcp";
      domains = [
        "www.fan-club-penguin.cz"
        "archiv.fan-club-penguin.cz"
        "beta.fan-club-penguin.cz"
        "cdn.fan-club-penguin.cz"
        "forum.fan-club-penguin.cz"
        "lisured.fan-club-penguin.cz"
        "mediacache.fan-club-penguin.cz"
        "preklady.fan-club-penguin.cz"
        "provider.fan-club-penguin.cz"
        "shout.fan-club-penguin.cz"
        "upload.fan-club-penguin.cz"
      ];
    };
  };

  services = {
    mysql = {
      enable = true;
    };

    phpfpm = rec {
      pools = {
        fcp = mkPhpPool {
          user = "fcp";
        };
      };
    };
  };

  users = {
    users = {
      jtojnar = {
        extraGroups = [
          "fcp"
        ];
      };

      nginx = {
        extraGroups = [
          "fcp"
        ];
      };

      fcp = { uid = 500; group = "fcp"; isSystemUser = true; };
    };

    groups = {
      fcp = { gid = 500; };
    };
  };
}
