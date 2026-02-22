{
  config,
  lib,
  myLib,
  pkgs,
  ...
}:

let
  domain = "pad.ogion.cz";
  port = 5004;

  inherit (myLib) mkVirtualHost;

  autheliaInstanceCfg = config.services.authelia.instances.default;
in

{
  age.secrets = {
    # For HedgeDoc, emulating Docker Secrets.
    # https://github.com/hedgedoc/hedgedoc/blob/cdedc8df33e6701650b5ae17a68d3f2a0efb9f2f/lib/config/dockerSecret.js#L60
    "hedgedoc-oauth-client-id" = {
      owner = config.users.users.hedgedoc.name;
      file = ../../../../secrets/authelia-default-oauth-client-id-hedgedoc.age;
      path = "/run/secrets/oauth2_clientID";
    };
    "hedgedoc-oauth-client-secret" = {
      owner = config.users.users.hedgedoc.name;
      file = ../../../../secrets/authelia-default-oauth-client-secret-hedgedoc.age;
      path = "/run/secrets/oauth2_clientSecret";
    };

    # For Authelia
    "authelia-default-oauth-client-id-hedgedoc" = {
      owner = config.users.users.${autheliaInstanceCfg.user}.name;
      file = ../../../../secrets/authelia-default-oauth-client-id-hedgedoc.age;
    };
  };

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "pad.ogion.cz" = mkVirtualHost {
          acme = "ogion.cz";
          # https://docs.hedgedoc.org/guides/reverse-proxy/#nginx
          locations =
            let
              proxyConfig = ''
                proxy_pass http://localhost:${builtins.toString config.services.hedgedoc.settings.port};
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $remote_addr;
                proxy_set_header X-Forwarded-Proto $scheme;
              '';

              localOnly = ''
                allow 2001:db8::/64;
                allow 192.0.2.0/24;
                deny all;
              '';
            in
            {
              "/" = {
                extraConfig = proxyConfig;
              };

              "/socket.io/" = {
                extraConfig = ''
                  ${proxyConfig}
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection $connection_upgrade;
                '';
              };

              "/metrics" = {
                extraConfig = ''
                  ${proxyConfig}
                  ${localOnly}
                '';
              };

              "/status" = {
                extraConfig = ''
                  ${proxyConfig}
                  ${localOnly}
                '';
              };
            };
        };
      };
    };

    hedgedoc = {
      enable = true;
      settings = {
        inherit domain port;
        protocolUseSSL = true;
        allowAnonymous = false;
        allowAnonymousEdits = true;
        defaultPermission = "limited";
        enableUploads = "none";

        db = {
          dialect = "postgres";
          user = "hedgedoc";
          host = "/run/postgresql";
          database = "hedgedoc";
        };

        # https://docs.hedgedoc.org/guides/auth/authelia/
        oauth2 = {
          providerName = "Authelia";
          # `clientID` amd `clientSecret` provided by agenix.
          scope = "openid email profile";
          userProfileUsernameAttr = "sub";
          userProfileDisplayNameAttr = "name";
          userProfileEmailAttr = "email";
          # https://www.authelia.com/integration/openid-connect/introduction/#discoverable-endpoints
          baseURL = "https://auth.ogion.cz/";
          authorizationURL = "https://auth.ogion.cz/api/oidc/authorization";
          tokenURL = "https://auth.ogion.cz/api/oidc/token";
          userProfileURL = "https://auth.ogion.cz/api/oidc/userinfo";
          pkce = true;
        };

        email = false;
      };
    };

    authelia.instances.default.settings.identity_providers.oidc.clients = [
      # https://docs.hedgedoc.org/guides/auth/authelia/
      # https://www.authelia.com/configuration/identity-providers/openid-connect/clients/
      {
        client_id = "{{ secret \"${
          config.age.secrets."authelia-default-oauth-client-id-hedgedoc".path
        }\" }}";
        client_name = "HedgeDoc";
        client_secret = "$pbkdf2-sha512$310000$tmF/OxS2dG78JrVoDP0sBg$eLvzQmp89OWq9tUSiNPVYI73hriPxbrYzwGjnboTOq0SOJ8g2EFGNBdFv14oPAH/pe7Jrc7nW/cqJeIwrd6SzA";
        redirect_uris = [
          "https://${domain}/auth/oauth2/callback"
        ];
        scopes = [
          "openid"
          "email"
          "profile"
        ];
        authorization_policy = "one_factor";
        require_pkce = true;
        # Access Request failed with error: Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method). The request was determined to be using 'token_endpoint_auth_method' method 'client_secret_post', however the OAuth 2.0 client registration does not allow this method. The registered client … is configured to only support 'token_endpoint_auth_method' method 'client_secret_basic'. Either the Authorization Server client registration will need to have the 'token_endpoint_auth_method' updated to 'client_secret_post' or the Relying Party will need to be configured to use 'client_secret_basic'.
        token_endpoint_auth_method = "client_secret_post";
      }
    ];
  };

  systemd.services.hedgedoc.after = [ "postgresql.target" ];

  custom.postgresql.databases = [
    {
      database = "hedgedoc";
    }
  ];
}
