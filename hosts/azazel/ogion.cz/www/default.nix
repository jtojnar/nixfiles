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
    nginx = {
      enable = true;

      commonHttpConfig = ''
        map $arg_resource $webfinger_resource {
          ~^(acct:[^/]+)$ $1;
          default nop;
        }
      '';

      virtualHosts = {
        "ogion.cz" = mkVirtualHost {
          acme = true;
          path = "ogion.cz/www";
          config = ''
            location = /.well-known/webfinger {
              alias ${webfingerRoot}/$webfinger_resource;
            }
          '';
        };

        "www.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          redirect = "ogion.cz";
        };
      };
    };
  };
}
