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

      extraUsers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of extra users with access to this database.";
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

      upgradeTargetPackage = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "PostgreSQL package that we want to upgrade to. When set, an update script will be installed.";
      };
    };
  };

  config = lib.mkIf (cfg.databases != []) {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      extraPlugins = lib.filter (x: x != null) (lib.concatMap ({extensions, ...}: map (ext: config.services.postgresql.package.pkgs.${ext} or null) extensions) cfg.databases);
      authentication = lib.mkForce ''
        local all postgres peer
        local sameuser all peer

        # extra users
        ${lib.concatMapStringsSep
          "\n"
          (
            {
              database,
              extraUsers,
              ...
            }:
            lib.concatMapStringsSep "\n" (user: "local ${database} ${user} peer") extraUsers
          )
          cfg.databases
        }
      '';
      ensureUsers =
        let
          dbToUsers =
            {
              database,
              extraUsers,
              ...
            }:
            # we use same username as dbname
            [ database ] ++ extraUsers;
        in
        map
          (name: { inherit name; })
          (lib.unique (builtins.concatMap dbToUsers cfg.databases));
    };

    systemd.services = {
      postgres-setup = let pgsql = config.services.postgresql; in {
        after = [ "postgresql.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pgsql.package ];
        script =
          lib.concatMapStringsSep "\n"
            ({ database, extensions, extraUsers, ... }:
              let
                createExtensionsSql = lib.concatMapStringsSep "; " (ext: ''CREATE EXTENSION IF NOT EXISTS "${ext}"'') extensions;
                createExtensionsIfAny = lib.optionalString (extensions != [ ]) ''
                  $PSQL -d '${database}' -c '${createExtensionsSql}'
                '';
              in ''
                set -eu

                PSQL="${pkgs.util-linux}/bin/runuser -u ${pgsql.superUser} -- psql --port=${toString pgsql.settings.port} --tuples-only --no-align"

                if ! $PSQL -c "SELECT 1 FROM pg_database WHERE datname = '${database}'" | grep --quiet 1; then
                    $PSQL -c 'CREATE DATABASE "${database}" WITH OWNER = "${database}"'
                    ${createExtensionsIfAny}
                fi
                ${lib.optionalString (extraUsers != []) "$PSQL '${database}' -c '${lib.concatMapStringsSep "\n" (user: "GRANT ALL ON ALL TABLES IN SCHEMA public TO ${user};") extraUsers}'"}
              '')
            cfg.databases;

        serviceConfig = {
          Type = "oneshot";
        };
      };

      postgresql.serviceConfig = {
        # Required by PLV8.
        MemoryDenyWriteExecute = false;
        SystemCallFilter = [
          "@pkey"
        ];
      };
    };

    # https://nixos.org/manual/nixos/unstable/#module-services-postgres-upgrading
    environment.systemPackages = lib.mkIf (cfg.upgradeTargetPackage != null) [
      (pkgs.writeScriptBin "upgrade-pg-cluster" ''
        set -eux
        # XXX it's perhaps advisable to stop all services that depend on postgresql
        systemctl stop postgresql

        export NEWDATA="/var/lib/postgresql/${cfg.upgradeTargetPackage.psqlSchema}"

        export NEWBIN="${cfg.upgradeTargetPackage}/bin"

        export OLDDATA="${config.services.postgresql.dataDir}"
        export OLDBIN="${config.services.postgresql.package}/bin"

        install -d -m 0700 -o postgres -g postgres "$NEWDATA"
        cd "$NEWDATA"
        sudo -u postgres $NEWBIN/initdb -D "$NEWDATA"

        sudo -u postgres $NEWBIN/pg_upgrade \
          --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
          --old-bindir $OLDBIN --new-bindir $NEWBIN \
          "$@"
      '')
    ];
  };

}
