{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4086";
      dev = true;
      x64sha256 = "/1iJXa9eTujAsvbAj9Jy1qLI7TU2ibOWaENnlKkr9QQ=";
      aarch64sha256 = "EHLj0TPpPOvOH/6HHBm2Ux0Ewr5MHGZQBptsBK9lM2A=";
    } {};
  }
