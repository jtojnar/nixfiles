let
  keys = import ../common/data/keys.nix;
in
{
  # https://www.authelia.com/configuration/miscellaneous/introduction/#jwt_secret
  "authelia-default-jwt.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];

  # https://www.authelia.com/configuration/identity-providers/openid-connect/provider/#hmac_secret
  "authelia-default-oidc-hmac-secret.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];

  # https://www.authelia.com/configuration/identity-providers/openid-connect/provider/#hmac_secret
  "authelia-default-oidc-jwk.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];

  # https://www.authelia.com/configuration/storage/introduction/#encryption_key
  "authelia-default-storage-encryption-key.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];

  # https://www.authelia.com/configuration/identity-providers/openid-connect/clients/#client_id
  # https://www.authelia.com/integration/openid-connect/frequently-asked-questions/#how-do-i-generate-a-client-identifier-or-client-secret
  "authelia-default-oauth-client-id-hedgedoc.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];

  # https://www.authelia.com/configuration/identity-providers/openid-connect/clients/#client_secret
  "authelia-default-oauth-client-secret-hedgedoc.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];

  "bag.ogion.cz-secret.age".publicKeys = builtins.concatLists [
    keys.azazel
    keys.jtojnar
  ];
  # https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#secret_key
  "monitor_grafana.ogion.cz-secret.age".publicKeys = builtins.concatLists [
    keys.azazel
    keys.jtojnar
  ];
  "ostrov-tucnaku.cz-telegram-api-key.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];
  "ostrov-tucnaku.cz-telegram-webhook-token.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];
  "gitea-token-jtojnar.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];
}
