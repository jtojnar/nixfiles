{
  config,
  lib,
  myLib,
  ...
}:

let
  inherit (myLib) mkVirtualHost;
in
{
  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "agenda.krk-litvinov.cz" = mkVirtualHost {
          # acme = "krk-litvinov.cz";
          acme = true;
          path = "krk-litvinov.cz/agenda";
          config = ''
            fancyindex on; # Enable directory listing.
            fancyindex_exact_size off; # Use human-readable file sizes.
          '';
        };
      };
    };
  };
}
