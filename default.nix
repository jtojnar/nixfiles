# A function so that this can be imported like nixpkgs by various update scripts and nixpkgs-hammering.
{
  # Required by nixpkgs-hammering.
  overlays ? [ ],
  ...
}:

let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  flake-compat = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
  };
  self = import flake-compat {
    src =  ./.;
  };

  packages = self.defaultNix.outputs.legacyPackages.${builtins.currentSystem};

  # Our `legacyPackages` are Nixpkgs’s `legacyPackages` overlaid with our custom packages
  # so we can just extend it further with the hammering overlays.
  packagesWithExtraOverlays = packages.appendOverlays overlays;
in
# Prepend all packages for current system so that various update scripts and nixpkgs-hammering can find the packages without having to recurse into outputs.
packagesWithExtraOverlays
// self.defaultNix
