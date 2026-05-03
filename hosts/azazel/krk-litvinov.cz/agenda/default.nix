{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "agenda.krk-litvinov.cz" = {
          useACMEHost = "krk-litvinov.cz";
          extraConfig = ''
            root * /var/www/krk-litvinov.cz/agenda
            file_server browse
          '';
        };
      };
    };
  };
}
