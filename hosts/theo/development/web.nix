{ config, inputs, pkgs, ... }:

let
  postgres = pkgs.postgresql_14;
in

{
  imports = [
    inputs.self.nixosModules.profiles.blackfire
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
      "selfoss.local" = {
        documentRoot = "/home/jtojnar/Projects/selfoss";
        extraConfig = ''
          <Directory "/home/jtojnar/Projects/selfoss">
            AllowOverride All
          </Directory>
        '';
      };
    };
    enablePHP = true;
    phpPackage = let
      libxml2 = pkgs.libxml2.overrideAttrs (attrs: {
        src = pkgs.fetchurl {
          url = "mirror://gnome/sources/libxml2/2.10/libxml2-2.10.2.tar.xz";
          sha256 = "0kCr5tqcZcsZAN2b86NQHM+Is8Khy5gxfQPyct2lsmU=";
        };
        patches = [];
      });
      replaceLibxml2 = prevArgs: {
        inherit libxml2;
      };
    in (pkgs.php80.override {
      inherit libxml2;
      callPackage = path: args: pkgs.callPackage path (args // { inherit libxml2; });
    }).withExtensions ({ enabled, all }: enabled ++ (with all; [
      blackfire
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
    extraConfig = ''
      DirectoryIndex index.php index.html
    '';
  };
}
