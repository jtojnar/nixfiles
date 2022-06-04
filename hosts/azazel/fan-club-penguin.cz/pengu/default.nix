{ config, lib, pkgs, myLib, ... }:

let

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

  systemd.packages = [
    pengu
  ];

  systemd.services = {
    pengu = {
      serviceConfig = {
        User = "pengu";
        Group = "pengu";
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
