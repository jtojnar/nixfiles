{ config, lib, pkgs,  ... }:
let
  myLib = import ../lib.nix { inherit lib config; };
  inherit (myLib) mkPhpPool;
in {
  imports = [
    ./archiv
    ./beta
    ./cdn
    ./forum
    ./kafu
    ./lisured
    ./mediacache
    ./preklady
    ./provider
    ./pengu
    ./saman
    ./shout
    ./upload
    ./www
  ];

  security.acme.certs."fan-club-penguin.cz".extraDomainNames = [
    "www.fan-club-penguin.cz"
    "archiv.fan-club-penguin.cz"
    "beta.fan-club-penguin.cz"
    "cdn.fan-club-penguin.cz"
    "forum.fan-club-penguin.cz"
    "kafu.fan-club-penguin.cz"
    "lisured.fan-club-penguin.cz"
    "mediacache.fan-club-penguin.cz"
    "preklady.fan-club-penguin.cz"
    "provider.fan-club-penguin.cz"
    "pengu.fan-club-penguin.cz"
    "saman.fan-club-penguin.cz"
    "shout.fan-club-penguin.cz"
    "upload.fan-club-penguin.cz"
  ];

  services = {
    mysql = {
      enable = true;

      ensureDatabases = [
        "cpforum"
        "fcp"
      ];
      ensureUsers = [
        { name = "cpforum"; ensurePermissions = { "cpforum.*" = "ALL PRIVILEGES"; }; }
        { name = "fcp"; ensurePermissions = { "fcp.*" = "ALL PRIVILEGES"; }; }
      ];
    };

    phpfpm = rec {
      pools = {
        fcp = mkPhpPool {
          user = "fcp";
        };
        cpforum = mkPhpPool {
          user = "cpforum";
        };
      };
    };
  };

  users = {
    users = {
      jtojnar = {
        extraGroups = [
          "fcp"
          "cpforum"
          "pengu"
        ];
      };

      nginx = {
        extraGroups = [
          "fcp"
          "cpforum"
        ];
      };

      fcp = { uid = 500; group = "fcp"; isSystemUser = true; };
      cpforum = { uid = 511; group = "cpforum"; isSystemUser = true; };
      pengu = { uid = 512; group = "pengu"; isSystemUser = true; };
    };

    groups = {
      fcp = { gid = 500; };
      cpforum = { gid = 511; };
      pengu = { gid = 512; };
    };
  };
}
