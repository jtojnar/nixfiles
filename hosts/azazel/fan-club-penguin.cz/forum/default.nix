{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:

let

  inherit (myLib) enablePHP mkVirtualHost;

  phpbb = pkgs.phpbb.withConfig {
    # enableInstaller = true;
    unitName = "cpforum";
    stateDir = "/var/www/fan-club-penguin.cz/cpforum";
    enabledPackages = with pkgs.phpbb.packages; [
      langs.cs
    ];
  };
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "forum.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            root * ${phpbb}

            @forbidden {
                path_regexp forbidden ^/(config\.php|common\.php|cache|files|images/avatars/upload|includes|phpbb|store|vendor|\.git|\.svn)
            }

            respond @forbidden 403

            handle_path /install/* {
                root * ${phpbb}

                @install_php path *.php
                reverse_proxy @install_php unix/${config.services.phpfpm.pools.fcp.socket} {
                    transport fastcgi {
                        split .php
                        read_timeout 500s
                    }
                }

                try_files {path} {path}/ /install/app.php?{query}

                file_server
            }

            ${enablePHP "fcp"} {
                try_files {path} {path}/ /app.php?{query}
            }

            file_server
          '';
        };
      };
    };
  };

  systemd = {
    services.phpfpm-cpforum = {
      serviceConfig = {
        CacheDirectory = "cpforum";
        CacheDirectoryMode = "700";
        # Needs to be a single command since systemd resets CacheDirectory owner before each command invocation.
        ExecStartPost = "/bin/sh -c '${
          lib.concatStringsSep ";" [
            # The service starts under “root” user and the phpfpm daemon then lowers the euid to “cpforum”.
            # But because systemd is not aware of that, the cache directory it creates does not have correct ownership.
            "${pkgs.coreutils}/bin/chown -R cpforum:cpforum %C/cpforum"
            "${config.security.wrapperDir}/sudo --preserve-env=CACHE_DIRECTORY -u cpforum ${phpbb}/bin/phpbbcli.php db:migrate"
            "${config.security.wrapperDir}/sudo --preserve-env=CACHE_DIRECTORY -u cpforum ${phpbb}/bin/phpbbcli.php cache:purge"
          ]
        }'";
      };
    };
  };
}
