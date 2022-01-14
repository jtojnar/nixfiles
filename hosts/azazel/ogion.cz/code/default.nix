{ config, lib, pkgs, ... }:

let
  domain = "code.ogion.cz";
  port = 5003;
in
{
  services = {
    gitea = {
      enable = true;
      appName = "ogion code forge";
      domain = domain;
      rootUrl = "https://${domain}/";
      httpPort = port;
      cookieSecure = true;
      disableRegistration = true;

      database = {
        type = "postgres";
        socket = "/run/postgresql";
        name = "gitea";
        user = "gitea";
        createDatabase = false;
      };

      lfs = {
        enable = true;
      };

      settings = {
        cors = {
          ENABLED = true;
          SCHEME = "https";
          ALLOW_DOMAIN = domain;
        };
        log = {
          MODE = "console";
        };
        mailer = {
          ENABLED = true;
          MAILER_TYPE = "sendmail";
          FROM = "noreply+code@ogion.cz";
          SENDMAIL_PATH = "/run/wrappers/bin/sendmail";
        };
        picture = {
          DISABLE_GRAVATAR = true;
        };
        repository = {
          DEFAULT_BRANCH = "main";
          DEFAULT_REPO_UNITS = "repo.code,repo.issues,repo.pulls";
        };
        server = {
          LANDING_PAGE = "explore";
        };
      };
    };

    nginx = {
      enable = true;

      virtualHosts = {
        "${domain}" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/" = {
              proxyPass = "http://${config.services.gitea.httpAddress}:${toString port}";
            };
          };
          extraConfig = ''
            if ($host !~* ^code\.ogion\.cz$ ) {
                return 444;
            }
          '';
        };
      };
    };
  };

  custom.postgresql.databases = [
    {
      database = "gitea";
    }
  ];
}
