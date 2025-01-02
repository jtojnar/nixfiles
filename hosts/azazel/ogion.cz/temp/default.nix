{
  config,
  lib,
  myLib,
  ...
}:

let
  inherit (myLib) mkVirtualHost;
in
{
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "temp.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          path = "ogion.cz/temp";
        };
      };
    };
  };
}
