{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4105";
      dev = true;
      x64sha256 = "004ikdj33i82cz6wyr974aqi8shpj7qbndlvfjssjx2ck8skng5v";
      aarch64sha256 = "1ikv0mswpz31l5qjzfk9ij3nw9hhd5q77mr4f8616cz654da1xxv";
    } {};
  }
