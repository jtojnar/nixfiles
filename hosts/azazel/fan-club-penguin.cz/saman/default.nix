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
        "saman.fan-club-penguin.cz" = mkVirtualHost {
          acme = "fan-club-penguin.cz";
          path = "fan-club-penguin.cz/saman";
        };
      };
    };
  };
}
