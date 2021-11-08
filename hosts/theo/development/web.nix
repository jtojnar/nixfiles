{ config, inputs, pkgs, ... }:

let
  postgres = pkgs.postgresql_11;
in

{
  imports = [
    inputs.self.nixosModules.profiles.blackfire
  ];

  networking.extraHosts = ''
    127.0.0.1 adminer.local
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
    package = pkgs.mariadb;
  };

  services.postfix = {
    enable = true;
  };

  services.httpd = {
    enable = true;
    adminAddr = "admin@localhost";
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
    };
    enablePHP = true;
    phpPackage = pkgs.php.withExtensions ({ enabled, all }: enabled ++ (with all; [
      blackfire
    ]));
    phpOptions = ''
      display_errors = 1
      display_startup_errors = 1
      error_reporting = E_ALL;
      ; Set up $_ENV superglobal.
      ; http://php.net/request-order
      variables_order = "EGPCS"
    '';
    extraConfig = ''
      DirectoryIndex index.php index.html
    '';
  };
}
