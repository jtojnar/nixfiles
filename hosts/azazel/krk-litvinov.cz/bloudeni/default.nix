{
  config,
  lib,
  myLib,
  ...
}:

let
  inherit (myLib) mkVirtualHost;

  path = "krk-litvinov.cz/bloudeni";
in
{

  systemd.tmpfiles.rules = [
    "d /var/www/${path} 0770 bloudeni bloudeni"
  ];

  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "bloudeni.krk-litvinov.cz" = {
          useACMEHost = "krk-litvinov.cz";
          extraConfig = ''
            root * /var/www/${path}
            file_server
          '';
        };
      };
    };
  };
}
