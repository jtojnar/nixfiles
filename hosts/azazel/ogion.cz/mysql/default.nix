{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP mkVirtualHost;

  wwwRoot = pkgs.adminer-with-plugins.override {
    theme = "brade";
    plugins = [
      "login-servers"
    ];
    pluginConfigs = ''
      new AdminerLoginServers([
        'localhost' => [
          'server' => 'localhost',
          // mysql is called server for BC:
          // https://github.com/vrana/adminer/blob/75cd1c3f286c31329072d9b6e3314a5b2b4ff5f0/adminer/drivers/mysql.inc.php#L6
          'driver' => 'server',
        ],
      ]),
    '';
    customStyle = ./adminer.css;
  };
in
{
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "mysql.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          root = wwwRoot;
          config = ''
            index index.php;

            location / {
              index index.php;
              try_files $uri $uri/ /index.php?$args;
            }

            location ~ \.php$ {
              ${enablePHP "adminer"}
              fastcgi_read_timeout 500;
            }
          '';
        };
      };
    };
  };
}
