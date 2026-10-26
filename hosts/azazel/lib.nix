{
  config,
  lib,
  pkgs,
  ...
}:

{
  mkVirtualHost =
    {
      path ? null,
      config ? "",
      acme ? null,
      redirect ? null,
      ...
    }@args:

    lib.optionalAttrs (lib.isString acme) {
      useACMEHost = acme;
      forceSSL = true;
    }
    // lib.optionalAttrs (lib.isBool acme) {
      enableACME = acme;
      forceSSL = true;
    }
    // lib.optionalAttrs (redirect != null) {
      globalRedirect = redirect;
    }
    // lib.optionalAttrs (path != null) {
      root = "/var/www/" + path;
    }
    // {
      extraConfig = config;
    }
    // builtins.removeAttrs args [
      "path"
      "config"
      "acme"
      "redirect"
    ];

  mkPhpPool =
    {
      user,
      debug ? false,
      settings ? { },
      ...
    }@args:

    {
      inherit user;
      settings = {
        "listen.acl_users" = lib.concatStringsSep "," [
          config.services.nginx.user
          config.services.prometheus.exporters.php-fpm.user
        ];
        "pm" = "dynamic";
        "pm.max_children" = 5;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 3;
        "pm.status_path" = "/status";
      }
      // lib.optionalAttrs debug {
        # log worker's stdout, but this has a performance hit
        "catch_workers_output" = true;
      }
      // settings;
    }
    // builtins.removeAttrs args [
      "user"
      "debug"
      "settings"
    ];

  enablePHP = sockName: ''
    fastcgi_pass unix:${config.services.phpfpm.pools.${sockName}.socket};
    include ${config.services.nginx.package}/conf/fastcgi.conf;
    fastcgi_param PATH_INFO $fastcgi_path_info;
    fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
  '';

  /*
    Adds extra options to ssh key that will only allow it to be used for rsync.
    See sshd(8) manual page for details.
  */
  restrictToRsync =
    directory: key: ''command="${pkgs.rrsync}/bin/rrsync -wo ${directory}",restrict ${key}'';

  /*
    Emulate systemd credentials.
    Those will only be available to the user the service is running under,
    not being aware of dropped euid.
    http://systemd.io/CREDENTIALS/
  */
  emulateCredentials =
    let
      parseCredential =
        credential:
        let
          matches = builtins.match "(.+):(.+)" credential;
        in
        assert lib.assertMsg (matches != null) "A credential needs to match “id:value” format";
        {
          id = builtins.elemAt matches 0;
          value = builtins.elemAt matches 1;
        };

      parseCredentials =
        credentials:
        builtins.map parseCredential (
          if builtins.isList credentials then credentials else lib.splitString "," credentials
        );
    in
    serviceConfig:
    lib.mkMerge [
      (builtins.removeAttrs serviceConfig [
        "SetCredential"
        "LoadCredential"
      ])
      {
        Environment = [
          "CREDENTIALS_DIRECTORY=${
            pkgs.runCommand "credentials" { } ''
              mkdir "$out"
              ${lib.concatMapStringsSep "\n" ({ id, value }: ''ln -s "${value}" "$out/${id}"'') (
                parseCredentials serviceConfig.LoadCredential or [ ]
              )}
              ${lib.concatMapStringsSep "\n" ({ id, value }: ''echo -n "${value}" > "$out/${id}"'') (
                parseCredentials serviceConfig.SetCredential or [ ]
              )}
            ''
          }"
        ];
      }
    ];
}
