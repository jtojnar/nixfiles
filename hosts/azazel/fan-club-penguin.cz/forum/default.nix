{ config, lib, pkgs, ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };

  inherit (myLib) enablePHP mkVirtualHost;

  phpbb = pkgs.phpbb.withConfig {
    # enableInstaller = true;
    unitName = "cpforum";
    stateDir = "/var/www/fan-club-penguin.cz/cpforum";
    enabledPackages = with pkgs.phpbb.packages; [
      langs.cs
    ];
  };
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "forum.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          root = phpbb;
          config = ''
            index index.php index.html index.htm;

            location / {
              # phpBB uses index.htm
              index index.php index.html index.htm;
              try_files $uri $uri/ @rewriteapp;
            }

            location @rewriteapp {
              rewrite ^(.*)$ /app.php/$1 last;
            }

            # Deny access to internal phpbb files.
            location ~ /(config\.php|common\.php|cache|files|images/avatars/upload|includes|phpbb|store|vendor) {
              deny all;
              # deny was ignored before 0.8.40 for connections over IPv6.
              # Use internal directive to prohibit access on older versions.
              internal;
            }

            # Pass the php scripts to fastcgi server specified in upstream declaration.
            location ~ \.php(/|$) {
              ${enablePHP "cpforum"}
              fastcgi_split_path_info ^(.+\.php)(/.*)$;
              try_files $uri $uri/ /app.php$is_args$args;
            }

            # Correctly pass scripts for installer
            location /install/ {
              # phpBB uses index.htm
              try_files $uri $uri/ @rewrite_installapp;

              # Pass the php scripts to fastcgi server specified in upstream declaration.
              location ~ \.php(/|$) {
                ${enablePHP "cpforum"}
                fastcgi_split_path_info ^(.+\.php)(/.*)$;
                try_files $uri $uri/ /install/app.php$is_args$args;
                fastcgi_read_timeout 500;
              }
            }

            location @rewrite_installapp {
              rewrite ^(.*)$ /install/app.php/$1 last;
            }

            # Deny access to version control system directories.
            location ~ /\.svn|/\.git {
              deny all;
              internal;
            }
          '';
        };
      };
    };
  };

  systemd = {
    services.phpfpm-cpforum = {
      serviceConfig = {
        CacheDirectory = "cpforum";
        ExecStartPost= [
          # The service starts under “root” user and the phpfpm daemon then lowers the euid to “cpforum”.
          # But because systemd is not aware of that, the cache directory it creates does not have correct ownership.
          "${pkgs.coreutils}/bin/chmod -R 700 %C/cpforum"
          "${pkgs.coreutils}/bin/chown -R cpforum:cpforum %C/cpforum"
        ];
      };
    };
  };
}
