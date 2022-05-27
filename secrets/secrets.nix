let
  keys = import ../common/data/keys.nix;
in
{
  "bag.ogion.cz-secret.age".publicKeys = builtins.concatLists [
    keys.azazel
    keys.jtojnar
  ];
  "blackfire-agent-server-id.age".publicKeys = builtins.concatLists [
    keys.azazel
    keys.theo

    keys.jtojnar
  ];
  "blackfire-agent-server-token.age".publicKeys = builtins.concatLists [
    keys.azazel
    keys.theo

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
}
