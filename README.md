# jtojnar’s configurations

## Structure
* `common`
    * `modules` – NixOS modules that will be auto-loaded by all configurations
    * `overlays` – Nixpkgs overlays that will be applied to package set
    * `profiles` – configuration profiles that can be imported
* `hosts`
    * `azazel` – VPS
    * `brian` – personal Ubuntu desktop (home-manager config)
    * `evan` – my brother’s desktop
    * `noelle` – laptop of my mother
    * `theo` – personal laptop
* `pkgs` – utilities and software not suitable/ready to be in Nixpkgs

## Commands

This repo contains some commands to be available in `nix-shell` to make deployment and maintenance easier.

### `deploy [hostname] {switch,boot,test}`

Wrapper around `nixos-rebuild` to avoid the need for specifying the full hostname and pass some default arguments.

### `deploy-home`

Wrapper around `home-manager` to avoid the need for specifying the full hostname and pass some default arguments.

### `update <attr-path>`

Run update script for a package on given attribute path.

## License

The source code is licensed under [MIT](LICENSE.md) (just like Nixpkgs).

I was inspired by configs of many other people so it does not feel natural to claim copyright over this code but I guess this is the safest way to allow other people to copy and reuse as I did.

I try to give credit where credit is due, at minimum in the commit messages. Hopefully I did not omit anyone.
