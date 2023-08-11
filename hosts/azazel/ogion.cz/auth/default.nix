{
  config,
  lib,
  myLib,
  pkgs,
  ...
}:

let
  inherit (myLib) mkVirtualHost;

  userData = import ../../../../common/data/users.nix;

  instanceCfg = config.services.authelia.instances.default;

  userOptions = {
    options = {
      authelia = {
        hashedPassword = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = lib.mdDoc ''
            Password hash generated with `nix run nixpkgs#authelia -- crypto hash generate argon2 --profile recommended`.
            If set, the user will be registered in Authelia and the hashed password will serve as the primary factor.
            See <https://www.authelia.com/reference/guides/passwords/#passwords>.
          '';
        };
      };
    };
  };
in

{
  imports = [
    {
      options = {
        # Add extra options to users module.
        users.users = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule userOptions);
        };
      };
    }
  ];

  age.secrets = {
    "authelia-default-jwt" = {
      owner = config.users.users.${instanceCfg.user}.name;
      file = ../../../../secrets/authelia-default-jwt.age;
    };
    "authelia-default-storage-encryption-key" = {
      owner = config.users.users.${instanceCfg.user}.name;
      file = ../../../../secrets/authelia-default-storage-encryption-key.age;
    };
  };

  custom.postgresql.databases = [
    {
      database = "authelia-default";
    }
  ];

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "auth.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          locations = {
            "/" = {
              proxyPass = "http://localhost:${builtins.toString instanceCfg.settings.server.port}";
            };
          };
        };
      };
    };

    authelia = {
      instances = {
        default = {
          enable = true;
          secrets = {
            jwtSecretFile = config.age.secrets."authelia-default-jwt".path;
            storageEncryptionKeyFile = config.age.secrets."authelia-default-storage-encryption-key".path;
          };

          settings = {
            # https://www.authelia.com/configuration/security/access-control/
            access_control = {
              default_policy = "deny";
              rules = [
                {
                  domain = "*.ogion.cz";
                  policy = "one_factor";
                }
              ];
            };

            authentication_backend = {
              # https://www.authelia.com/configuration/first-factor/file/
              file = {
                # https://www.authelia.com/reference/guides/passwords/#yaml-format
                path = pkgs.writeTextFile {
                  name = "authelia-accounts.yaml";
                  text = lib.generators.toYAML { } {
                    users =
                      let
                        usersWithPassword = lib.filterAttrs (_name: user: user.authelia.hashedPassword != null) config.users.users;

                        mkUser =
                          name:
                          {
                            authelia,
                            group,
                            extraGroups,
                            ...
                          }:

                          {
                            disabled = false;
                            displayname = userData.${name}.name;
                            password = authelia.hashedPassword;
                            email = userData.${name}.email;
                            groups = [ group ] ++ extraGroups;
                          };
                      in
                      lib.mapAttrs mkUser usersWithPassword;
                  };
                };
              };

              password_reset = {
                # Passwords are set declaratively.
                disable = true;
              };
            };

            session = {
              domain = "ogion.cz";
            };

            storage = {
              postgres = {
                host = "/run/postgresql";
                database = "authelia-default";
                # 4.37.5 requires explicitly specified port for sockets.
                port = "5432";
                username = "authelia-default";
                # This is meaningless with socket.
                password = "foo";
              };
            };

            theme = "auto";

            # Not used yet.
            totp.disable = true;
            webauthn.disable = true;
          };
        };
      };
    };
  };

  systemd.services.authelia-default = {
    after = [
      "postgresql.service"
    ];

    serviceConfig = rec {
      LogsDirectory = "authelia";
      Environment = [
        "AUTHELIA_NOTIFIER_FILESYSTEM_FILENAME=%L/${LogsDirectory}/events.log"
      ];
    };
  };

  # https://www.authelia.com/overview/security/measures/#more-protections-measures-with-fail2ban
  services.fail2ban = {
    jails = {
      # max 3 failures in the last day
      "authelia" = ''
        enabled = true
        port = http,https,${builtins.toString instanceCfg.settings.server.port}
        filter = authelia
        maxretry = 3
        bantime = 1d
        findtime = 1d
      '';
    };
  };

  environment.etc = {
    "fail2ban/filter.d/authelia.conf".text = ''
      [Definition]
      failregex = ^.*Unsuccessful 1FA authentication attempt by user .*remote_ip="?<HOST>"? stack.*
        ^.*Unsuccessful (TOTP|Duo|U2F) authentication attempt by user .*remote_ip="?<HOST>"? stack.*
      ignoreregex = ^.*level=debug.*
        ^.*level=info.*
        ^.*level=warning.*
      journalmatch = _SYSTEMD_UNIT=authelia-default.service
    '';
  };
}
