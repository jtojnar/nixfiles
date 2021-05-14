{ config, lib, pkgs,  ... }:
let
  myLib = import ../../lib.nix { inherit lib config; };
  inherit (myLib) enablePHP mkVirtualHost;

  adminer = pkgs.adminer.overrideAttrs (attrs: {
    postInstall = attrs.postInstall or "" + ''
      mkdir $out/plugins
      cp plugins/{plugin,enum-option,login-servers}.php $out/plugins
      cp designs/brade/adminer.css $out/brade.css
    '';
  });

  # If we want to use otp plug-in, we cannot have adminer.php accessible since that does not load plug-ins and would allow bypassing the otp plug-in.
  wwwRoot = pkgs.runCommand "adminer-with-plugins" {
    inherit adminer;
  } ''
    mkdir -p "$out"
    substituteAll "${./index.php}" "$out/index.php"
    ln -s "${adminer}/brade.css" $out/brade.css
    cp "${./adminer.css}" "$out/adminer.css"
  '';
in {
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
