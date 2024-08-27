{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnome-boxes
    spice-gtk
    virt-manager
  ];

  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.libvirtd.enable = true;
}
