{ config, lib, pkgs, myLib, ... }:
let
  inherit (myLib) enablePHP mkVirtualHost;

  flarum = pkgs.flarum.withConfig {
    unitName = "ostrov-tucnaku";
    stateDir = "/var/www/ostrov-tucnaku.cz/www";
    config = {
      debug = false;
      database = {
        driver = "mysql";
        host = "localhost";
        database = "ostrov-tucnaku";
        username = "ostrov-tucnaku";
        charset = "utf8mb4";
        collation = "utf8mb4_unicode_ci";
        prefix = "";
        strict = false;
      };
      url = "https://ostrov-tucnaku.cz";
      paths = {
        api = "api";
        admin = "admin";
      };
    };
  };
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "ostrov-tucnaku.cz" = mkVirtualHost {
          root = "${flarum}/public";
          acme = true;
          config = ''
            location ~* \.php$ {
              ${enablePHP "ostrov-tucnaku"}
            }

            index index.php;

            include ${flarum}/.nginx.conf;

            client_max_body_size 10M;
          '';
        };

        "www.ostrov-tucnaku.cz" = mkVirtualHost {
          acme = "ostrov-tucnaku.cz";
          redirect = "ostrov-tucnaku.cz";
        };
      };
    };
  };

  systemd = {
    services.phpfpm-ostrov-tucnaku = {
      serviceConfig = {
        CacheDirectory = "ostrov-tucnaku";
        CacheDirectoryMode = "700";
        # Needs to be a single command since systemd resets CacheDirectory owner before each command invocation.
        ExecStartPost = "/bin/sh -c '${lib.concatStringsSep ";" [
          # The service starts under “root” user and the phpfpm daemon then lowers the euid to “ostrov-tucnaku”.
          # But because systemd is not aware of that, the cache directory it creates does not have correct ownership.
          "${pkgs.coreutils}/bin/chown -R ostrov-tucnaku:ostrov-tucnaku %C/ostrov-tucnaku"
          "${config.security.wrapperDir}/sudo --preserve-env=CACHE_DIRECTORY -u ostrov-tucnaku ${pkgs.coreutils}/bin/mkdir -p $(find ${flarum}/storage -mindepth 1 -maxdepth 1 -type d -printf  '%C/ostrov-tucnaku/%%P')"
          "${config.security.wrapperDir}/sudo --preserve-env=CACHE_DIRECTORY -u ostrov-tucnaku ${flarum}/flarum migrate"
          "${config.security.wrapperDir}/sudo --preserve-env=CACHE_DIRECTORY -u ostrov-tucnaku ${flarum}/flarum cache:clear"
        ]}'"
        ;
      };
    };
  };
}
