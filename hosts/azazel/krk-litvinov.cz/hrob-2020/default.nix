{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "hrob-2020.krk-litvinov.cz" = {
          useACMEHost = "krk-litvinov.cz";
          extraConfig = ''
            root * /var/www/krk-litvinov.cz/hrob-2020
            file_server
          '';
        };
      };
    };
  };
}
