{ config, pkgs, ... }:
{
  systemd.services.wrcq = {
    description = "Prequalified Entrants";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "postgresql.service" ];

    serviceConfig = {
      PermissionsStartOnly = true;
      User = "jtojnar";
      Group = "users";
      ExecStart = "${pkgs.nodejs-9_x}/bin/node /media/OldRoot/home/jtojnar/Dropbox/Private/projects/wrcQ/index.js";
      WorkingDirectory = "/media/OldRoot/home/jtojnar/Dropbox/Private/projects/wrcQ";
      Restart = "always";
      RestartSec = "10";
    };

    environment = {
      DATABASE_URL = "postgres://postgres:postgres@localhost/pqe";
      NODE_ENV = "development";
    };
  };
}
