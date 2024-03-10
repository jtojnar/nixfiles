# theo

This is configuration for my personal desktop computer. I sometimes transfer the primary drive to my laptop (Sony VAIO Fit 15E). Running GNOME Shell and trying to configure as much as possible declaratively using NixOS modules.

## Installation

The following is based on [Disko quickstart](https://github.com/nix-community/disko/blob/master/docs/quickstart.md).

### Step 1: Boot the installer

This includes downloading/creating the ISO image, writing it on a flash drive, and booting from it. See [Martin’s tutorial](https://gist.github.com/martijnvermaat/76f2e24d0239470dd71050358b4d5134#preparing-installation-media) or [Disko quickstart](https://github.com/nix-community/disko/blob/master/docs/quickstart.md#step-2-boot-the-installer) for more info.

Then clone this repo with `git clone https://github.com/jtojnar/nixfiles.git`.

### Step 2: Retrieve the disk name

Disko [suggests](https://github.com/nix-community/disko/blob/master/docs/quickstart.md#step-3-retrieve-the-disk-name) using `lsblk` to find the disk name (e.g. `sdc`) but that is [not persistent](https://wiki.archlinux.org/title/Persistent_block_device_naming), especially when I tend to move the disk between different devices. Unfortunately, we cannot use `by-uuid` or `by-label` since that only applies to file systems. The only persistent identifier appears to be [World Wide Name](https://wiki.archlinux.org/title/Persistent_block_device_naming#World_Wide_Name), which is listed under `by-id`.

Searching the output of `udisksctl dump` for `Samsung` I found the target disk and noted the WWN listed under “Symlinks”: `/dev/disk/by-id/wwn-0x5002538f33815e01`. I then set `disko.devices.disk.theo-evo870.device` in `disko-config.nix` to that value.

### Step 3: Partition format and and mount


```
sudo touch /tmp/secret.key
sudo chmod 600 /tmp/secret.key
sudo nano /tmp/secret.key --nonewlines

nix shell disko
sudo disko --mode format hosts/theo/disko-config.nix
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko hosts/theo/disko-config.nix
```

`nixos-generate-config --root /tmp/config --no-filesystems`

### Step 4: Complete the NixOS installation

```
nixos-generate-config --no-filesystems --root /tmp
cp /tmp/etc/nixos/hardware-configuration.nix hosts/theo/
nixos-install
reboot
```


Set up LVM in LUKS, follow <https://gist.github.com/martijnvermaat/76f2e24d0239470dd71050358b4d5134>.

Swap file will be created automatically, just need to update `resume_offset` in `boot.kernelParams` and `boot.resumeDevice`.

