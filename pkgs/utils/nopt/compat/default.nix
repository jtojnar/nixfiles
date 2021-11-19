{
  flakePath,
  ...
}:

let
  flake = import flakePath { };
in
flake.legacyPackages.${builtins.currentSystem}
