{
  ...
}:

{
  services = {
    nginx = {
      enable = true;

      commonHttpConfig = ''
        map $arg_duration $results_file {
            "" index.html;
            default index-$arg_duration.html;
        }
      '';

      virtualHosts = {
        "pqe.rogaining.org" = {
          enableACME = true;
          forceSSL = true;
          root = "/var/www/rogaining.org/pqe";
          extraConfig = ''
            location ~ ^/events/(?<slug>[^/\s]+)/results$ {
                if ($arg_duration = 24) {
                    return 302 /events/$slug/results;
                }

                rewrite ^/events/(?<slug>[^/\s]+)/results$ /events/$slug/results/$results_file break;

                try_files $uri =404;
            }

            if ($host !~* ^pqe\.rogaining\.org$ ) {
                return 444;
            }
          '';
        };
      };
    };
  };

  users = {
    users = {
      pqe = {
        uid = 509;
        group = "pqe";
        isSystemUser = true;
      };
    };

    groups = {
      pqe = {
        gid = 509;
      };
    };
  };
}
