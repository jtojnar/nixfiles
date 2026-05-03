{
  config,
  lib,
  myLib,
  pkgs,
  ...
}:

let
  inherit (myLib) mkVirtualHost;

  # Mostly static config
  # https://gist.github.com/aaronpk/5846789
  mkWebfingerAccount =
    name:
    {
      authelia,
      ...
    }:

    let
      subject = "acct:${name}@ogion.cz";
    in
    pkgs.writeTextFile {
      name = subject;
      destination = "/${subject}";
      text = lib.generators.toJSON { } {
        inherit subject;
        links = lib.optionals (authelia.hashedPassword != null) [
          {
            rel = "http://openid.net/specs/connect/1.0/issuer";
            href = "https://auth.ogion.cz";
          }
        ];
      };
    };

  webfingerRoot = pkgs.symlinkJoin {
    name = "ogion.cz-webfinger";
    paths = builtins.attrValues (
      lib.mapAttrs mkWebfingerAccount (lib.filterAttrs (name: user: user.isNormalUser) config.users.users)
    );
  };
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "ogion.cz" = {
          useACMEHost = "ogion.cz";
          extraConfig = ''
            root * /var/www/ogion.cz/www
            file_server

            handle /.well-known/webfinger {
              root * ${webfingerRoot}
              rewrite * /{query.resource}
              file_server
            }
          '';
        };

        "www.ogion.cz" = {
          useACMEHost = "ogion.cz";
          extraConfig = ''
            redir https://ogion.cz{uri} permanent
          '';
        };
      };
    };
  };
}
