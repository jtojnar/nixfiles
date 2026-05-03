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
        "beta.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            @not_beta {
              not header Cookie (^|;\s*)beta=1($|;)
            }

            respond @not_beta 401

            root * /var/www/fan-club-penguin.cz/@beta/current/www
            file_server
            ${enablePHP "fcp"}
          '';
        };
      };
    };
  };
}
