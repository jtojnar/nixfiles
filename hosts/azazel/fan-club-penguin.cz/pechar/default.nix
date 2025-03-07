{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP mkVirtualHost mkPhpPool;
in
{
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "pechar.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          root = pkgs.pechar;
          config = ''
            index index.html;

            location / {
              try_files $uri $uri/ =404;
            }

            location ~ /data/composed/get\.php$ {
              ${enablePHP "pechar"}
            }

            location ~ /data/composed/(.+)\.png {
              root /var/cache/pechar;
              try_files /$1.png /data/composed/get.php?path=$1;
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
