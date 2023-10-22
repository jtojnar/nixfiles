{
  ...
}:

{
  services.fail2ban = {
    enable = true;

    bantime = "10m";
    bantime-increment.enable = true;

    jails = {
      # max 3 failures in 600 seconds
      "sshd-unaunth-dos" = ''
        enabled = true
        filter = sshd-unaunth-dos
        findtime = 600
        maxretry = 3
      '';
    };
  };

  environment.etc = {
    "fail2ban/filter.d/sshd-unaunth-dos.conf".text = ''
      [Definition]
      failregex = fatal: Timeout before authentication for <HOST> port \d+$
      journalmatch = _SYSTEMD_UNIT=sshd.service
    '';
  };
}

