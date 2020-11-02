{ config, lib, pkgs, ... }:

let
  myLib = import ../../lib.nix { inherit lib config; };

  inherit (myLib) mkVirtualHost;

  pengu = pkgs.pengu;

  port = 5002;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "pengu.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          locations = {
            "/" = {
              proxyPass = "http://localhost:${toString port}";
              proxyWebsockets = true;
            };
          };
        };
      };
    };
  };

  custom.postgresql.databases = [
    {
      database = "pengu";
    }
  ];

  systemd.services = {
    pengu = {
      description = "Pengu virtual chat";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];

      serviceConfig = {
        User = "pengu";
        Group = "pengu";
        ExecStart = "${pkgs.nodejs-15_x}/bin/node ${pengu}/src";
        WorkingDirectory = pengu;
        Restart = "always";
        RestartSec = "10";
      };

      environment = {
        DATABASE_URL = "socket:/run/postgresql?db=pengu";
        PORT = toString port;
        OPENID_PROVIDER = "https://provider.fan-club-penguin.cz";
        OPENID_REALM = "https://pengu.fan-club-penguin.cz/";
        OPENID_VERIFY = "https://pengu.fan-club-penguin.cz/verify";
        ACCEPTED_ORIGINS = "pengu.fan-club-penguin.cz";
      };
    };
  };
}
