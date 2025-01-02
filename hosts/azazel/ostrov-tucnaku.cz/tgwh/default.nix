{
  config,
  lib,
  pkgs,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP mkVirtualHost;
in
{
  age.secrets = {
    "ostrov-tucnaku.cz-telegram-api-key" = {
      owner = config.users.users.ostrov-tucnaku.name;
      file = ../../../../secrets/ostrov-tucnaku.cz-telegram-api-key.age;
    };
    "ostrov-tucnaku.cz-telegram-webhook-token" = {
      owner = config.users.users.ostrov-tucnaku.name;
      file = ../../../../secrets/ostrov-tucnaku.cz-telegram-webhook-token.age;
    };
  };

  systemd.services.phpfpm-ostrov-tucnaku.serviceConfig = myLib.emulateCredentials {
    SetCredential = [
      "botName:fanclubpenguinbot"
      "chatId:-1001043436793"
    ];
    LoadCredential = [
      "apiKey:${config.age.secrets."ostrov-tucnaku.cz-telegram-api-key".path}"
      "token:${config.age.secrets."ostrov-tucnaku.cz-telegram-webhook-token".path}"
    ];
  };

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "tgwh.ostrov-tucnaku.cz" = mkVirtualHost {
          root = "${pkgs.flarum-webhooks-telegram-bridge}/share/php/flarum-webhooks-telegram-bridge";
          acme = "ostrov-tucnaku.cz";
          config = ''
            index index.php;

            location ~* \.php$ {
              ${enablePHP "ostrov-tucnaku"}
            }
          '';
        };
      };
    };
  };
}
