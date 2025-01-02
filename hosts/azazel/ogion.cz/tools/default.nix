{
  config,
  lib,
  myLib,
  pkgs,
  ...
}:

let
  inherit (myLib) enablePHP mkPhpPool mkVirtualHost;
in
{
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "tools.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          path = "ogion.cz/tools";
          locations = {
            "/pdf/password-remover" =
              let
                tool = pkgs.substituteAll {
                  src = ./pdf/password-remover.php;
                  qpdf = "${lib.getBin pkgs.qpdf}/bin/qpdf";
                };
              in
              {
                extraConfig = ''
                  ${enablePHP "tools"}
                  fastcgi_param SCRIPT_FILENAME ${tool};
                '';
              };
          };
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
