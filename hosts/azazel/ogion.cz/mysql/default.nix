{
  pkgs,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP;

  wwwRoot = pkgs.adminer-with-plugins.override {
    theme = "brade";
    plugins = [
      "enum-option"
      "login-servers"
    ];
    pluginConfigs = ''
      new AdminerEnumOption,
      new AdminerLoginServers([
        'localhost' => [
          'server' => 'localhost',
          // mysql is called server for BC:
          // https://github.com/vrana/adminer/blob/75cd1c3f286c31329072d9b6e3314a5b2b4ff5f0/adminer/drivers/mysql.inc.php#L6
          'driver' => 'server',
        ],
      ]),
    '';
    customStyle = ./adminer.css;
  };
in
{
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "mysql.ogion.cz" = {
          useACMEHost = "ogion.cz";
          extraConfig = ''
            root * ${wwwRoot}
            file_server
            ${enablePHP "adminer"}
          '';
        };
      };
    };
  };
}
