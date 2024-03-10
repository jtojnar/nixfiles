{
  disko.devices = {
    disk = {
      theo-evo870 = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x5002538f33815e01";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "800M";
              type = "EF00"; # EFI
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                extraOpenArgs = [ ];
                settings = {
                  # if you want to use the key for interactive login be sure there is no trailing newline
                  # for example use `echo -n "password" > /tmp/secret.key`
                  keyFile = "/tmp/secret.key";
                  allowDiscards = true;
                };
                content = {
                  type = "lvm_pv";
                  vg = "theo-evo870-vg";
                };
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      theo-evo870-vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
            };
          };
        };
      };
    };
  };
}
