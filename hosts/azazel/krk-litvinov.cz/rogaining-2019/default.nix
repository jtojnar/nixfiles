{
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP;
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "rogaining-2019.krk-litvinov.cz" = {
          useACMEHost = "krk-litvinov.cz";
          extraConfig = ''
            root * /var/www/krk-litvinov.cz/rogaining-2019
            file_server
            ${enablePHP "rogaining-2019"}
          '';
        };
      };
    };
  };
}
