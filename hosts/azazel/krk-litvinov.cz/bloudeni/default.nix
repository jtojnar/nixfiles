{ config, lib, myLib, ... }:
let
  inherit (myLib) mkVirtualHost;

  path = "krk-litvinov.cz/bloudeni";
in {

  systemd.tmpfiles.rules = [
    "d /var/www/${path} 0770 bloudeni bloudeni"
  ];

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "bloudeni.krk-litvinov.cz" = mkVirtualHost {
          acme = true;
          inherit path;
        };
      };
    };
  };
}
