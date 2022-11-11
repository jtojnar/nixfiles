# So that this can be imported like nixpkgs by various update scripts.
{ ... }:
let
  self = import (
    let
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);
    in
      fetchTarball {
        url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
        sha256 = lock.nodes.flake-compat.locked.narHash;
      }
  ) {
    src =  ./.;
  };
in
  # So that various update scripts can find the packages.
  self.defaultNix.outputs.legacyPackages.${builtins.currentSystem}
  // self.defaultNix
