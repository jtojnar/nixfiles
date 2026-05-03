{
  config,
  ...
}:

{
  systemd.tmpfiles.rules = [
    "d ${config.services.caddy.virtualHosts."hrob-2022.krk-litvinov.cz".root} 0770 hrob-2022 hrob-2022"
  ];

  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "hrob-2022.krk-litvinov.cz" = {
          useACMEHost = "krk-litvinov.cz";
          extraConfig = ''
            root * /var/www/krk-litvinov.cz/hrob-2022
            file_server
          '';
        };
      };
    };
  };
}
