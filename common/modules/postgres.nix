{ config, lib, pkgs, ... }:

let
  inherit (lib) types mkOption;

  cfg = config.custom.postgresql;

  database = { name, ... }: {
    options = {
      database = mkOption {
        type = types.str;
        description = "Database name";
      };

      extensions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of extensions to install and enable.";
      };
    };
  };

in

{
  options = {
    custom.postgresql = {
      databases = mkOption {
        type = types.listOf (types.submodule database);
        default = [];
        description = "List of databases to set up.";
      };
    };
  };

  config = lib.mkIf (cfg.databases != []) {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_11;
      extraPlugins = lib.filter (x: x != null) (lib.concatMap ({extensions, ...}: map (ext: config.services.postgresql.package.pkgs.${ext} or null) extensions) cfg.databases);
      authentication = lib.mkForce ''
        local all postgres peer
        local sameuser all peer
      '';
      ensureUsers = map ({database, ...}: {
        name = database; # we use same username as dbname
      }) cfg.databases;
    };

    systemd.services = {
      postgres-setup = let pgsql = config.services.postgresql; in {
        after = [ "postgresql.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pgsql.package ];
        script =
          lib.concatMapStringsSep "\n"
            ({ database, extensions, ... }:
              let
                createExtensionsSql = lib.concatMapStringsSep "; " (ext: ''CREATE EXTENSION IF NOT EXISTS "${ext}"'') extensions;
                createExtensionsIfAny = lib.optionalString (extensions != [ ]) ''
                  $PSQL -d '${database}' -c '${createExtensionsSql}'
                '';
              in ''
                set -eu

                PSQL="${pkgs.util-linux}/bin/runuser -u ${pgsql.superUser} -- psql --port=${toString pgsql.port} --tuples-only --no-align"

                if ! $PSQL -c "SELECT 1 FROM pg_database WHERE datname = '${database}'" | grep --quiet 1; then
                    $PSQL -c 'CREATE DATABASE "${database}" WITH OWNER = "${database}"'
                    ${createExtensionsIfAny}
                fi
              '')
            cfg.databases;

        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
  };

}
