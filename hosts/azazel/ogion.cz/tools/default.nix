{
  config,
  lib,
  myLib,
  pkgs,
  ...
}:

let
  inherit (myLib) enablePHP mkPhpPool;

  password-remover = pkgs.replaceVars ./pdf/password-remover.php {
    qpdf = "${lib.getBin pkgs.qpdf}/bin/qpdf";
  };
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "tools.ogion.cz" = {
          useACMEHost = "ogion.cz";
          extraConfig = ''
            root * /var/www/ogion.cz/tools

            handle /pdf/password-remover {
              reverse_proxy unix/${config.services.phpfpm.pools.tools.socket} {
                transport fastcgi {
                  env SCRIPT_FILENAME ${password-remover}
                }
              }
            }

            file_server
          '';
        };
      };
    };

    phpfpm = rec {
      pools = {
        tools = mkPhpPool {
          user = "tools";
        };
      };
    };
  };
}
