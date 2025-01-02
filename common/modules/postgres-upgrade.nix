{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) types mkOption;

  cfg = config.custom.postgresql;

in
{
  options = {
    custom.postgresql = {
      upgradeTargetPackage = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "PostgreSQL package that we want to upgrade to. When set, an update script will be installed.";
      };
    };
  };

  config = {

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
