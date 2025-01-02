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
        "hrob-2020.krk-litvinov.cz" = mkVirtualHost {
          # acme = "krk-litvinov.cz";
          acme = true;
          path = "krk-litvinov.cz/hrob-2020";
        };
      };
    };
  };
}
