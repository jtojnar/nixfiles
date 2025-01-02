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
        "develop.ogion.cz" = mkVirtualHost {
          # acme = "ogion.cz";
          path = "ogion.cz/develop";
        };
      };
    };
  };
}
