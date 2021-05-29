{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    dwarffs
  ];

  # Needs to match `systemd-escape -p --suffix=mount "$XDG_RUNTIME_DIR/dwarffs"`
  # TODO: figure out how to make it more transferable.
  systemd.user.mounts.run-user-1000-dwarffs = {
    Unit = {
      Description = "Debug Symbols File System";
      Documentation = "https://github.com/edolstra/dwarffs";

      # From https://github.com/nix-community/home-manager/pull/1629
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Install = {
      # From https://github.com/nix-community/home-manager/pull/1629
      WantedBy = [ "graphical-session.target" ];
    };

    Mount = {
      What = "none";
      Where = "%t/dwarffs";
      Type = "fuse.dwarffs";
      # On Ubuntu, the group name is the same as the user name.
      # Since we run it as a user service, we do not need allow_other.
      Options = "ro,cache=%C/dwarffs,uid=${config.home.username},gid=${config.home.username}";
      StandardOutput = "journal";
      StandardError = "journal";
      Environment = [
        "IN_SYSTEMD=1"
      ];
    };

  };

  systemd.user.sessionVariables.NIX_DEBUG_INFO_DIRS = "$XDG_RUNTIME_DIR/dwarffs";

  systemd.user.tmpfiles.rules = [
    "d %C/dwarffs 0755 ${config.home.username} ${config.home.username} 7d"
    # `mount.fuse.dwarffs` needs to exist on the default PATH in order for mount to be able to use it.
    # https://github.com/libfuse/libfuse/issues/19
    # Since home-manager cannot write to /sbin, let’s create a symlink in a stable location
    # and create a symlink from /sbin there manually using
    # `sudo ln -s $XDG_CACHE_HOME/mount.fuse.dwarffs /sbin/mount.fuse.dwarffs`
    "L+ %C/mount.fuse.dwarffs - - - - ${pkgs.dwarffs}/bin/dwarffs"
  ];
}
