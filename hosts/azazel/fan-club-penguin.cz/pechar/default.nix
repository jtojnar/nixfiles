{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP mkPhpPool;
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "pechar.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            @composed_cached path_regexp ^/data/composed/(.+)\.png$
            @fallback path *
            @composed_gen path /data/composed/get.php

            root * /var/www/fan-club-penguin.cz/pechar
            file_server

            handle @composed_cached {
                rewrite * /{re.composed_cached.1}.png

                root * /var/cache/pechar
                try_files {path} @fallback

                file_server
            }

            handle @fallback {
                rewrite * /data/composed/get.php?path={re.png.1}
                ${enablePHP "pechar"} {
                    transport fastcgi {
                        split .php
                    }
                }
            }

            reverse_proxy @composed_gen unix/${config.services.phpfpm.pools.pechar.socket} {
                transport fastcgi {
                    split .php
                }
            }

            handle {
                try_files {path} {path}/ =404
                file_server
            }
          '';
        };
      };
    };

    phpfpm = rec {
      pools = {
        pechar = mkPhpPool {
          user = "pechar";
          phpOptions = ''
            ; Set up $_ENV superglobal.
            ; http://php.net/request-order
            variables_order = "EGPCS"
          '';
          phpEnv = {
            MEDIA_SERVER_LOCAL_DIRECTORY = "/var/www/fan-club-penguin.cz/mediacache/from-fcp";
          };
          settings = {
            # Accept settings from the systemd service.
            clear_env = false;
          };
        };
      };
    };
  };

  systemd.services.phpfpm-pechar = {
    serviceConfig = {
      CacheDirectory = "pechar";
      ExecStartPost = [
        # The service starts under “root” user and the phpfpm daemon then lowers the euid to “pechar”.
        # But because systemd is not aware of that, the cache directory it creates does not have correct ownership.
        "${pkgs.coreutils}/bin/chmod -R 700 %C/pechar"
        "${pkgs.coreutils}/bin/chown -R pechar:pechar %C/pechar"
      ];
    };
  };
}
