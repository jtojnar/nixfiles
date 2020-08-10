{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4081";
      dev = true;
      x64sha256 = "BZVh8fP9CYcL/ltddeBcii4tTA2JC1H7bIdzEWf0X+E=";
      aarch64sha256 = "W/IJbUUdVcyj4LA8ChAaqyzz0N8cJNDlYq4acsIdysE=";
    } {};
  }
