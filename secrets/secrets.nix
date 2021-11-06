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
    keys.jtojnar
  ];
  "blackfire-agent-server-token.age".publicKeys = builtins.concatLists [
    keys.azazel
    keys.jtojnar
  ];
}
