{ config, myLib, ... }:
let
  inherit (myLib) mkVirtualHost;
in {
  systemd.tmpfiles.rules = [
    "d ${config.services.nginx.virtualHosts."hrob-2022.krk-litvinov.cz".root} 0770 hrob-2022 hrob-2022"
  ];

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "hrob-2022.krk-litvinov.cz" = mkVirtualHost {
          acme = true;
          path = "krk-litvinov.cz/hrob-2022";
        };
      };
    };
  };
}
