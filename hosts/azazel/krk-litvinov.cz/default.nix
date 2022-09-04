{ config, lib, pkgs, myLib, ... }:
let
  inherit (myLib) mkPhpPool;
in {
  imports = [
    ./agenda
    ./bloudeni
    ./entries
    ./hrob-2020
    ./hrob-2022
    ./lob-2019
    ./rogaining-2019
    ./skirogaining
  ];

  # security.acme.certs."krk-litvinov.cz".extraDomainNames = [
  #   "bloudeni.krk-litvinov.cz"
  #   "entries.krk-litvinov.cz"
  # ];

  services = {
    mysql = {
      enable = true;

      ensureDatabases = [
        "entries"
        "rogaining-2019"
      ];
      ensureUsers = [
        { name = "entries"; ensurePermissions = { "entries.*" = "ALL PRIVILEGES"; }; }
        { name = "rogaining-2019"; ensurePermissions = { "\\`rogaining-2019\\`.*" = "ALL PRIVILEGES"; }; }
        {
          name = "tojnar";
          ensurePermissions = {
            "entries.*" = "DELETE, INSERT, SELECT, UPDATE";
          };
        }
      ];
    };

    phpfpm = rec {
      pools = {
        entries = mkPhpPool {
          user = "entries";
          debug = true;
        };
        rogaining-2019 = mkPhpPool {
          user = "rogaining-2019";
          debug = true;
        };
        skirogaining = mkPhpPool {
          user = "skirogaining";
          debug = true;
        };
      };
    };
  };

  users = {
    users = {
      jtojnar = {
        extraGroups = [
          "bloudeni"
          "entries"
          "hrob-2022"
          "rogaining-2019"
          "skirogaining"
        ];
      };

      tojnar = {
        extraGroups = [
          "bloudeni"
          "entries"
          "hrob-2022"
          "krk"
          "skirogaining"
        ];
      };

      nginx = {
        extraGroups = [
          "bloudeni"
          "entries"
          "hrob-2022"
          "krk"
          "rogaining-2019"
          "skirogaining"
        ];
      };

      bloudeni = { uid = 513; group = "bloudeni"; isSystemUser = true; };
      entries = { uid = 504; group = "entries"; isSystemUser = true; };
      hrob-2022 = { uid = 520; group = "hrob-2022"; isSystemUser = true; };
      krk = { uid = 505; group = "krk"; isSystemUser = true; };
      rogaining-2019 = { uid = 507; group = "rogaining-2019"; isSystemUser = true; };
      skirogaining = { uid = 517; group = "skirogaining"; isSystemUser = true; };
    };

    groups = {
      bloudeni = { gid = 513; };
      entries = { gid = 504; };
      hrob-2022 = { gid = 520; };
      krk = { gid = 505; };
      rogaining-2019 = { gid = 507; };
      skirogaining = { gid = 517; };
    };
  };
}
