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
        "mechmice.ogion.cz" = mkVirtualHost {
          path = "ogion.cz/mechmice";
          acme = "ogion.cz";
        };
      };
    };
  };
}
