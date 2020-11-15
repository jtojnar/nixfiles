{ config, lib, pkgs,  ... }:
let
  myLib = import ../lib.nix { inherit lib config; };
  inherit (myLib) mkPhpPool;
in {
  imports = [
    ./agenda
    ./bloudeni
    ./entries
    ./entries.rogaining-2019
    ./hrob-2020
    ./lob-2019
    ./rogaining-2019
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
        "entries-2019"
        "rogaining-2019"
      ];
      ensureUsers = [
        { name = "entries"; ensurePermissions = { "entries.*" = "ALL PRIVILEGES"; }; }
        { name = "entries-2019"; ensurePermissions = { "\\`entries-2019\\`.*" = "ALL PRIVILEGES"; }; }
        { name = "rogaining-2019"; ensurePermissions = { "\\`rogaining-2019\\`.*" = "ALL PRIVILEGES"; }; }
        {
          name = "tojnar";
          ensurePermissions = {
            "entries.*" = "DELETE, INSERT, SELECT, UPDATE";
            "\\`entries-2019\\`.*" = "DELETE, INSERT, SELECT, UPDATE";
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
        entries-2019 = mkPhpPool {
          user = "entries-2019";
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
          "rogaining-2019"
          "entries-2019"
        ];
      };

      tojnar = {
        extraGroups = [
          "bloudeni"
          "entries"
          "krk"
          "entries-2019"
        ];
      };

      nginx = {
        extraGroups = [
          "bloudeni"
          "entries"
          "krk"
          "rogaining-2019"
          "entries-2019"
        ];
      };

      bloudeni = { uid = 513; group = "bloudeni"; isSystemUser = true; };
      entries = { uid = 504; group = "entries"; isSystemUser = true; };
      krk = { uid = 505; group = "krk"; isSystemUser = true; };
      rogaining-2019 = { uid = 507; group = "rogaining-2019"; isSystemUser = true; };
      entries-2019 = { uid = 508; group = "entries-2019"; isSystemUser = true; };
    };

    groups = {
      bloudeni = { gid = 513; };
      entries = { gid = 504; };
      krk = { gid = 505; };
      rogaining-2019 = { gid = 507; };
      entries-2019 = { gid = 508; };
    };
  };
}
