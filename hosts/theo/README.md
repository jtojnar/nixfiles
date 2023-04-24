# theo

This is configuration for my personal desktop computer. I sometimes transfer the primary drive to my laptop (Sony VAIO Fit 15E). Running GNOME Shell and trying to configure as much as possible declaratively using NixOS modules.

## Installation

Set up LVM in LUKS, follow <https://gist.github.com/martijnvermaat/76f2e24d0239470dd71050358b4d5134>.

Swap file will be created automatically, just need to update `resume_offset` in `boot.kernelParams` and `boot.resumeDevice`.

