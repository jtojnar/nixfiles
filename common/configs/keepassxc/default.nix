{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    keepassxc
  ];

  home.file.".config/keepassxc/keepassxc.ini".source = ./keepassxc.ini;
  home.file.".mozilla/native-messaging-hosts/org.keepassxc.keepassxc_browser.json".source =
    pkgs.replaceVars ./nmh.json
      {
        inherit (pkgs) keepassxc;
      };
}
