{ config, lib, pkgs, myLib, ... }:
let
  inherit (myLib) enablePHP mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "simplepie.ogion.cz" = mkVirtualHost {
          path = "ogion.cz/simplepie";
          config = ''
            index index.php index.html;

            location ~ \.php$ {
              ${enablePHP "adminer"}
              fastcgi_read_timeout 500;
            }
          '';
        };
      };
    };
    vsftpd = {
      enable = true;
      writeEnable = true;
      userlist = [
        "adminer"
      ];
      localUsers = true;
      extraConfig = ''
        pasv_min_port=51000
        pasv_max_port=51999
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    20
    21
  ];
  networking.firewall.allowedTCPPortRanges = [
    { from = 51000; to = 51999; }
  ];
}
