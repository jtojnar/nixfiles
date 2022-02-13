{ config, lib, myLib, ... }:
let
  inherit (myLib) mkVirtualHost;
in {
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "obrazky.ostrov-tucnaku.cz" = mkVirtualHost {
          path = "ostrov-tucnaku.cz/obrazky";
          acme = "ostrov-tucnaku.cz";
          config = ''
            location ~* \.(css|js|gif|jpe?g|png)$ {
              expires 1M;
              add_header Pragma public;
              add_header Cache-Control "public, must-revalidate, proxy-revalidate";
            }
          '';
        };
      };
    };
  };
}
