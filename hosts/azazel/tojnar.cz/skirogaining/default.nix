{
  ...
}:

{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "skirogaining.tojnar.cz" = {
          useACMEHost = "tojnar.cz";
          extraConfig = ''
            handle_path /Skirogaining_2010/* {
              redir https://skirogaining.krk-litvinov.cz/2010{uri} permanent
            }

            handle {
              redir https://skirogaining.krk-litvinov.cz/2012{uri} permanent
            }
          '';
        };
      };
    };
  };
}
