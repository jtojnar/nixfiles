{
  pkgs,
  lib,
  config,
  ...
}:

let
  python = pkgs.python3.withPackages (pp: [
    pp.requests
    pp.beautifulsoup4
    pp.prometheus-client
  ]);

  pushgatewayUri = "localhost${config.services.prometheus.pushgateway.web.listen-address}";

in

{
  systemd.timers."lego-bdp-scraper" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "53s";
      OnUnitActiveSec = "53s";
      Unit = "lego-bdp-scraper.service";
    };
  };

  systemd.services."lego-bdp-scraper" = {
    script = ''
      set -eu
      ${python.interpreter} ${./extractor.py} --prometheus-uri=${pushgatewayUri}
    '';
    after = [
      "pushgateway.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      StateDirectory = "lego-bdp";
    };
  };
}
