{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnome.gnome-boxes
    spice-gtk
  ];

  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.libvirtd.enable = true;
}
