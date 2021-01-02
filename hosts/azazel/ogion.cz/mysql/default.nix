{ config, lib, pkgs,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;

  adminer = pkgs.adminer.overrideAttrs (attrs: {
    postInstall = attrs.postInstall or "" + ''
      cp ${./index.php} $out/index.php
      cp ${./adminer.css} $out/adminer.css
      mkdir $out/plugins
      cp plugins/{plugin,enum-option,login-servers}.php $out/plugins
      cp designs/brade/adminer.css $out/brade.css
    '';
  });
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "mysql.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          root = adminer;
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
