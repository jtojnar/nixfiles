{ config, lib, pkgs, myLib, ... }:
let
  inherit (myLib) enablePHP mkPhpPool mkVirtualHost;

  datadir = "/var/www/ogion.cz/bag";

  package = pkgs.wallabag.overrideAttrs (attrs: {
    patches = attrs.patches or [] ++ [
      # Use sendmail from php.ini
      (pkgs.fetchpatch {
        url = "https://github.com/symfony/swiftmailer-bundle/commit/31a4fed8f621f141ba70cb42ffb8f73184995f4c.patch";
        stripLen = 1;
        extraPrefix = "vendor/symfony/swiftmailer-bundle/";
        sha256 = "rxHiGhKFd/ZWnIfTt6omFLLoNFlyxOYNCHIv/UtxCho=";
      })
    ];
  });

  # Based on https://github.com/wallabag/wallabag/blob/c018d41f908343cb79bfc09f4ed5955c46f65b15/app/config/parameters.yml.dist
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

    mailer_transport = "sendmail";
    mailer_user = null;
    mailer_password = null;
    mailer_host = null;
    mailer_port = null;
    mailer_encryption = null;
    mailer_auth_mode = null;

    locale = "en";

    # A secret key that's used to generate certain security-related tokens
    # We use agenix so we need to substitute it at activation time.
    secret = "@secret@";

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

  configFileTemplate = pkgs.writeTextFile {
    name = "wallabag-config";
    text = builtins.toJSON {
      parameters = settings;
    };
  };

  configFileLink = pkgs.runCommandLocal "wallabag-config-link" { } ''
    mkdir -p "$out/config"
    ln -s "/etc/wallabag/parameters.yml" "$out/config/parameters.yml"
  '';

  appDir = pkgs.buildEnv {
    name = "wallabag-app-dir";
    ignoreCollisions = true;
    checkCollisionContents = false;
    paths = [
      configFileLink
      "${package}/app"
    ];
  };

  php = pkgs.php74.withExtensions ({ enabled, all }: enabled ++ (with all; [
    imagick
    tidy
  ]));
in {
  custom.postgresql.databases = [
    {
      database = "bag";
    }
  ];

  age.secrets = {
    "bag.ogion.cz-secret".file = ../../../../secrets/bag.ogion.cz-secret.age;
  };

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "bag.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          root = "${package}/web";

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

          locations."/assets".root = "${package}/app/web";

          locations."~ ^/app\\.php(/|$)" = {
            extraConfig = ''
              ${enablePHP "bag"}
              fastcgi_param SCRIPT_FILENAME ${package}/web/$fastcgi_script_name;
              fastcgi_param DOCUMENT_ROOT ${package}/web;
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
          user = "bag";
          debug = true;
          phpPackage = php;
          settings = {
            "env[WALLABAG_DATA]" = datadir;
          };
        };
      };
    };
  };

  # We use agenix so we need to create the config at activation time.
  system.activationScripts."bag.ogion.cz-secret" = lib.stringAfter [ "etc" "agenix" "agenixRoot" ] ''
    secret=$(cat "${config.age.secrets."bag.ogion.cz-secret".path}")
    configDir=/etc/wallabag
    mkdir -p "$configDir"
    configFile=$configDir/parameters.yml
    ${pkgs.gnused}/bin/sed "s#@secret@#$secret#" "${configFileTemplate}" > "$configFile"
    chown -R bag:nginx "$configDir"
    chmod 700 "$configDir"
    chmod 600 "$configFile"
  '';

  systemd.services.wallabag-install = {
    description = "Wallabag install service";
    wantedBy = [ "multi-user.target" ];
    before = [ "phpfpm-bag.service" ];
    after = [ "postgresql.service" ];
    path = with pkgs; [ coreutils php phpPackages.composer ];

    serviceConfig = {
      User = "bag";
      Type = "oneshot";
      RemainAfterExit = "yes";
      PermissionsStartOnly = true;
    };

    preStart = ''
      mkdir -p "${datadir}"
      chown bag:nginx "${datadir}"
    '';

    script = ''
      echo "Setting up wallabag files in ${datadir} ..."
      cd "${datadir}"
      rm -rf var/cache/*
      rm -f app
      ln -sf "${appDir}" app
      ln -sf ${package}/composer.{json,lock} .
      export WALLABAG_DATA="${datadir}"
      if [ ! -f installed ]; then
        mkdir -p data
        php ${package}/bin/console --env=prod wallabag:install
        touch installed
      else
        php ${package}/bin/console --env=prod doctrine:migrations:migrate --no-interaction
      fi
      php ${package}/bin/console --env=prod cache:clear
    '';
  };
}
