{
  pkgs,
  ...
}:

let

  pengu = pkgs.pengu;

  port = 5002;
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "pengu.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            reverse_proxy localhost:${toString port}
          '';
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
      wantedBy = [ "multi-user.target" ];
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
