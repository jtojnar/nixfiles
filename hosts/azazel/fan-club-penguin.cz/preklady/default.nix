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
        "preklady.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            root * /var/www/fan-club-penguin.cz/preklady

            handle /comic/* {
              try_files {path} {path}/ /comic/index.php?{query}
              ${enablePHP "fcp"}
              file_server
            }

            handle /comic/data/prelozit/* {
              file_server browse
            }

            handle /library/* {
              try_files {path} {path}/ /comic/index.php?{query}
              ${enablePHP "fcp"}
              file_server
            }
          '';
        };
      };
    };
  };
}
