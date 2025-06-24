{
  pkgs,
  lib,
  ...
}:

{
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  systemd.user.timers."cargo-sweep" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Unit = "cargo-sweep.service";
    };
  };

  systemd.user.services."cargo-sweep" = {
    path = [
      pkgs.cargo
      pkgs.cargo-sweep
    ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.cargo} sweep --recursive --time 30 %h";
      Type = "oneshot";
    };
  };
}
