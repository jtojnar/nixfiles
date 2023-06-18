{ config, lib, pkgs, ... }:

let
  postgres = pkgs.postgresql_14;
in

{
  imports = [
  ];

  networking.extraHosts = ''
    127.0.0.1 adminer.local
    127.0.0.1 selfoss.local
  '';

  services.postgresql = {
    enable = true;
    package = postgres;
    enableTCPIP = true;
    extraPlugins = [ postgres.pkgs.plv8 ];
    authentication = ''
      local all all trust
      host all all 10.0.0.28/0 trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb_1011;
  };

  services.postfix = {
    enable = true;
  };

  services.phpfpm.pools.dev = {
    inherit (config.services.httpd) user group;
    settings = {
      "listen.owner" = config.services.httpd.user;
      "listen.group" = config.services.httpd.group;
      "pm" = "dynamic";
      "pm.max_children" = 5;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 4;
      "pm.max_requests" = 500;
    };

    phpPackage = pkgs.php.withExtensions ({ enabled, all }: enabled ++ (with all; [
    ]));

    phpOptions = ''
      display_errors = 1
      display_startup_errors = 1
      error_reporting = E_ALL;
      ; Set up $_ENV superglobal.
      ; http://php.net/request-order
      variables_order = "EGPCS"
      post_max_size = "20M"
      upload_max_filesize = "20M"
      memory_limit = "512M"
      max_execution_time = "1800"
    '';
  };
  systemd.services."phpfpm-dev".serviceConfig = {
    # Allow accessing ~/Projects.
    ProtectHome = lib.mkForce false;
  };

  services.httpd = {
    enable = true;
    adminAddr = "admin@localhost";
    extraModules = [
      "proxy_fcgi"
    ];
    virtualHosts = {
      localhost = {
        documentRoot = "/home/jtojnar/Projects";
        extraConfig = ''
          <Directory "/home/jtojnar/Projects">
            AllowOverride All
          </Directory>
        '';
      };
      "adminer.local" = {
        documentRoot = pkgs.adminer-with-plugins.override {
          theme = "brade";
          plugins = [
            "enum-option"
          ];
          pluginConfigs = ''
            new AdminerEnumOption,
            new class {
                // Allow empty passwords again.
                public function login($login, $password) {
                    return true;
                }
            },
          '';
        };
      };
      "selfoss.local" = {
        documentRoot = "/home/jtojnar/Projects/selfoss";
        extraConfig = ''
          <Directory "/home/jtojnar/Projects/selfoss">
            AllowOverride All
          </Directory>
        '';
      };
    };
    extraConfig = ''
      DirectoryIndex index.php index.html

      <FilesMatch "\.php$">
        SetHandler "proxy:unix:${config.services.phpfpm.pools.dev.socket}|fcgi://localhost/"
      </FilesMatch>
    '';
  };
}
