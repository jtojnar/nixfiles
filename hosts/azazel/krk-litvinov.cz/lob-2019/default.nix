{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "lob-2019.krk-litvinov.cz" = {
          useACMEHost = "krk-litvinov.cz";
          extraConfig = ''
            root * /var/www/krk-litvinov.cz/lob-2019
            file_server
          '';
        };
      };
    };
  };
}
