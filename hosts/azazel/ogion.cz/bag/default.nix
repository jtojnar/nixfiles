{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP mkPhpPool mkVirtualHost;

  wallabag = pkgs.wallabag.overrideAttrs (attrs: {
    patches =
      builtins.filter (patch: builtins.baseNameOf patch != "wallabag-data.patch") attrs.patches
      ++ [
        # Out of the box, Wallabag wants to write to various subdirectories of the project directory.
        # Let’s replace references to such paths with designated systemd locations
        # so that the project source can remain immutable.
        ./wallabag-data.patch

        # Allow passing command flag to sendmail transport.
        (pkgs.fetchpatch {
          url = "https://github.com/symfony/symfony/commit/665d1cd3fa9638b655f032a8b8658bc6c3b4e305.patch";
          hash = "sha256-hBJJOqVSQzI6g7Zkuw8zzHUky40XZU5iAFYe6oqER3Y=";
          stripLen = 5;
          extraPrefix = "vendor/symfony/mailer/";
          includes = [
            "vendor/symfony/mailer/Transport/SendmailTransportFactory.php"
          ];
        })
      ];
  });

  # Based on https://github.com/wallabag/wallabag/blob/2.6.6/app/config/parameters.yml.dist
  settings = {
    database_driver = "pdo_pgsql";
    database_host = null;
    database_port = 5432;
    database_name = "bag";
    database_user = "bag";
    database_password = null;
    database_path = null;
    database_table_prefix = null;
    database_socket = "/run/postgresql";
    database_charset = "utf8";

    domain_name = "https://bag.ogion.cz";
    server_name = "Wallabag";

    # Needs an explicit command since Symfony version used by Wallabag does not yet support the `native` transport
    # and the `sendmail` transport does not respect `sendmail_path` configured in `php.ini`.
    mailer_dsn = "sendmail://default?command=/run/wrappers/bin/sendmail%%20-t%%20-i";

    locale = "en";

    # A secret key that's used to generate certain security-related tokens.
    "env(SECRET_FILE)" = config.age.secrets."bag.ogion.cz-secret".path;
    secret = "%env(file:resolve:SECRET_FILE)%";

    # two factor stuff
    twofactor_auth = true;
    twofactor_sender = "bag@ogion.cz";

    # fosuser stuff
    fosuser_registration = false;
    fosuser_confirmation = false;

    # how long the access token should live in seconds for the API
    fos_oauth_server_access_token_lifetime = 3600;
    # how long the refresh token should life in seconds for the API
    fos_oauth_server_refresh_token_lifetime = 1209600;

    from_email = "bag@ogion.cz";

    # RabbitMQ processing
    rabbitmq_host = null;
    rabbitmq_port = null;
    rabbitmq_user = null;
    rabbitmq_password = null;
    rabbitmq_prefetch_count = null;

    # Redis processing
    redis_scheme = null;
    redis_host = null;
    redis_port = null;
    redis_path = null;
    redis_password = null;

    # sentry logging
    sentry_dsn = null;
  };

  # Pin to fix “Implicitly marking parameter as nullable is deprecated” in PHP 8.4
  php = pkgs.php83.withExtensions (
    { enabled, all }:
    enabled
    ++ (with all; [
      imagick
      tidy
    ])
  );

  commonServiceConfig = {
    CacheDirectory = "wallabag";
    # Stores sessions.
    CacheDirectoryMode = "700";
    ConfigurationDirectory = "wallabag";
    LogsDirectory = "wallabag";
    StateDirectory = "wallabag";
    # Stores site-credentials-secret-key.txt.
    StateDirectoryMode = "700";
  };
in
{
  custom.postgresql.databases = [
    {
      database = "bag";
    }
  ];

  age.secrets = {
    "bag.ogion.cz-secret" = {
      owner = config.users.users.bag.name;
      file = ../../../../secrets/bag.ogion.cz-secret.age;
    };
  };

  environment.etc."wallabag/parameters.yml" = {
    source = pkgs.writeTextFile {
      name = "wallabag-config";
      text = builtins.toJSON {
        parameters = settings;
      };
    };
  };

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "bag.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          root = "${wallabag}/web";

          extraConfig = ''
            add_header X-Frame-Options SAMEORIGIN;
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
          '';

          locations."/" = {
            extraConfig = ''
              try_files $uri /app.php$is_args$args;
            '';
          };

          locations."/assets".root = "${wallabag}/app/web";

          locations."~ ^/app\\.php(/|$)" = {
            extraConfig = ''
              ${enablePHP "bag"}
              fastcgi_param SCRIPT_FILENAME ${wallabag}/web/$fastcgi_script_name;
              fastcgi_param DOCUMENT_ROOT ${wallabag}/web;
              fastcgi_read_timeout 120;
              internal;
            '';
          };

          locations."~ /(?!app)\\.php$" = {
            extraConfig = ''
              return 404;
            '';
          };
        };
      };
    };

    phpfpm = rec {
      pools = {
        bag = mkPhpPool {
          user = config.users.users.bag.name;
          debug = true;
          phpPackage = php;
          phpOptions = ''
            ; Set up $_ENV superglobal.
            ; http://php.net/request-order
            variables_order = "EGPCS"
            # Wallabag will crash on start-up.
            # https://github.com/wallabag/wallabag/issues/6042
            error_reporting = E_ALL & ~E_USER_DEPRECATED & ~E_DEPRECATED
          '';
          settings = {
            # Accept settings from the systemd service.
            clear_env = false;
          };
        };
      };
    };
  };

  systemd.services.phpfpm-bag.serviceConfig = commonServiceConfig;

  systemd.services.wallabag-install = {
    description = "Wallabag install service";
    wantedBy = [ "multi-user.target" ];
    before = [ "phpfpm-bag.service" ];
    after = [ "postgresql.service" ];
    path = with pkgs; [
      coreutils
      php
      phpPackages.composer
    ];

    serviceConfig = {
      User = "bag";
      Type = "oneshot";
    } // commonServiceConfig;

    script = ''
      if [ ! -f "$STATE_DIRECTORY/installed" ]; then
        php ${wallabag}/bin/console --env=prod wallabag:install
        touch "$STATE_DIRECTORY/installed"
      else
        php ${wallabag}/bin/console --env=prod doctrine:migrations:migrate --no-interaction
      fi
      php ${wallabag}/bin/console --env=prod cache:clear
    '';
  };
}
