let
  keys = import ../common/data/keys.nix;
in
{
  # https://www.authelia.com/configuration/miscellaneous/introduction/#jwt_secret
  "authelia-default-jwt.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];
  # https://www.authelia.com/configuration/storage/introduction/#encryption_key
  "authelia-default-storage-encryption-key.age".publicKeys = builtins.concatLists [
    keys.azazel

    keys.jtojnar
  ];
  "bag.ogion.cz-secret.age".publicKeys = builtins.concatLists [
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
