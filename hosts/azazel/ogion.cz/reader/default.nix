{ config, inputs, lib, pkgs, myLib, ... }:
let
  inherit (myLib) enablePHP mkPhpPool mkVirtualHost;

  settings = {
    debug = "1";
    username = "jtojnar";
    password = "$2y$10$vLbhYNg4KvHQOCggf1rrx.pVcALVYG.zEkYuBMXWEqOE84u/wOSzS";
    auto_mark_as_read = "1";
    share = "p";
    homepage = "unread";
    # TZ = "Europe/Prague";
    TZ = "UTC";
    datadir = "/var/www/ogion.cz/reader/data";
    logger_destination = "file:php://stderr";
    logger_level = "DEBUG";
    base_url = "https://reader.ogion.cz/";
    items_lifetime = "0";
    # selfoss_scroll_to_article_header = "0";
    open_in_background_tab = "1";
  };

  settingsEnv = lib.mapAttrs' (name: value: lib.nameValuePair "selfoss_${name}" value) settings;

  php = pkgs.php.withExtensions ({ enabled, all }: enabled ++ (with all; [
  ]));

  # Modify the upstream nginx config to point to our mutable datadir.
  nginxConf =
    pkgs.runCommand
      "selfoss.nginx.conf"
      {
        src = "${pkgs.selfoss}/.nginx.conf";
      }
      ''
        substitute "$src" "$out" \
          --replace 'try_files $uri /data/$uri;' 'root ${settings.datadir};'
      '';
in {
  imports = [
  ];

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "reader.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          root = pkgs.selfoss;
          config = ''
            include ${nginxConf};

            location ~ \.php$ {
              ${enablePHP "reader"}
            }
          '';
        };
      };
    };

    phpfpm = rec {
      pools = {
        reader = mkPhpPool {
          user = "reader";
          debug = true;
          phpPackage = php;
          phpOptions = ''
            ; Set up $_ENV superglobal.
            ; http://php.net/request-order
            variables_order = "EGPCS"
          '';
          settings = {
            # Accept settings from the systemd service.
            clear_env = false;
          };
        };
      };
    };
  };

  # I was not able to pass the variables through services.phpfpm.pools.reader.phpEnv:
  # https://github.com/NixOS/nixpkgs/issues/79469#issuecomment-631461513
  systemd.services.phpfpm-reader.environment = settingsEnv;

  systemd.services.selfoss-update = {
    serviceConfig = {
      ExecStart = "${php}/bin/php ${pkgs.selfoss}/cliupdate.php";
      User = "reader";
    };
    environment = settingsEnv;
    startAt = "hourly";
    wantedBy = [ "multi-user.target" ];
  };
}
