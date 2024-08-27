{ config, lib, pkgs, myLib, ... }:
let
  inherit (myLib) mkPhpPool restrictToRsync;
in {
  imports = [
    ./cyklogaining
    ./krk
    ./skirogaining
    ./www
  ];

  security.acme.certs."tojnar.cz".extraDomainNames = [
    "cyklogaining.tojnar.cz"
    "krk.tojnar.cz"
    "skirogaining.tojnar.cz"
    "www.tojnar.cz"
  ];

  services = {
    phpfpm = rec {
      pools = {
        cyklogaining = mkPhpPool {
          user = "cyklogaining";
          debug = true;
        };
        tojnar-cz = mkPhpPool {
          user = "tojnar-cz";
          debug = true;
        };
      };
    };
  };

  users = {
    users = {
      jtojnar = {
        extraGroups = [
          "cyklogaining"
          "tojnar-cz"
        ];
      };

      nginx = {
        extraGroups = [
          "cyklogaining"
          "tojnar-cz"
        ];
      };

      cyklogaining = { uid = 516; group = "cyklogaining"; isSystemUser = true; };
      tojnar-cz = {
        uid = 518;
        group = "tojnar-cz";
        isSystemUser = true;
        openssh.authorizedKeys.keys =
          builtins.concatMap (user: config.users.users.${user}.openssh.authorizedKeys.keys) [
            "jtojnar"
            "tojnar"
          ];
        shell = "/bin/sh";
      };
    };

    groups = {
      cyklogaining = { gid = 516; };
      tojnar-cz = { gid = 518; };
    };
  };
}
