{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnome3.gnome-boxes
    spice-gtk
  ];

  security.wrappers.spice-client-glib-usb-acl-helper.source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";

  virtualisation.libvirtd.enable = true;

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "jtojnar" ];
  virtualisation.virtualbox.host.enableExtensionPack = true;
}
