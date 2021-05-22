{
  ...
}:

let
  flake = import (builtins.getEnv "FLAKE_PATH");
in
flake.nixosConfigurations.${builtins.getEnv "HOSTNAME"}
