{ config, pkgs, ... }:
{
  networking.firewall.allowedUDPPorts = [ 1900 ];
  networking.firewall.extraPackages = [ pkgs.conntrack_tools ];
  environment.etc.networking.firewall.autoLoadConntrackHelpers = true;
  networking.firewall.extraCommands = ''
    nfct add helper ssdp inet udp
    iptables --verbose -I OUTPUT -t raw -p udp --dport 1900 -j CT --helper ssdp
  '';
}
