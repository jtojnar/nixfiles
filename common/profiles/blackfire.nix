{ config, lib, pkgs, ... }:
{
  age.secrets = {
    "blackfire-agent-server-id".file = ../../secrets/blackfire-agent-server-id.age;
    "blackfire-agent-server-token".file = ../../secrets/blackfire-agent-server-token.age;
  };

  services.blackfire-agent = {
    enable = true;
    settings = {
      # We use agenix so we need to substitute it at activation time.
      server-id = "@serverId@";
      server-token = "@serverToken@";
    };
  };

  # We use agenix so we need to create the config at activation time.
  system.activationScripts."blackfire-secret-secret" = lib.stringAfter [ "etc" "agenix" "agenixRoot" ] ''
    serverId=$(cat "${config.age.secrets."blackfire-agent-server-id".path}")
    serverToken=$(cat "${config.age.secrets."blackfire-agent-server-token".path}")
    ${pkgs.gnused}/bin/sed -i "s#@serverId@#$serverId#;s#@serverToken@#$serverToken#" "/etc/blackfire/agent"
  '';
}
