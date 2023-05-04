{ config, lib, pkgs, myLib, ... }:
let
  inherit (myLib) enablePHP mkVirtualHost;

  passwordFile =
    pkgs.writeText
      "simplepie.htpasswd"
      ''
        # generated with `htpasswd -c /dev/stdout test`
        test:$apr1$NIPEds8j$19uLqdh7eW8.dX96MPYdY1
      '';
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "simplepie.ogion.cz" = mkVirtualHost {
          path = "ogion.cz/simplepie";
          config = ''
            index index.php index.html;

            auth_basic "SimplePie test page, use test:test to log in";
            auth_basic_user_file ${passwordFile};

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
