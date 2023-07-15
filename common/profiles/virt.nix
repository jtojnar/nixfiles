{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnome.gnome-boxes
    spice-gtk
    virt-manager
  ];

  virtualisation.spiceUSBRedirection.enable = true;

  virtualisation.libvirtd.enable = true;
}
