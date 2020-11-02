{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4090";
      dev = true;
      x64sha256 = "1g8rjxx16v5zxa054qy8yaizg1y6iczp7vfw5idwb6rhjrfjddny";
      aarch64sha256 = "0dz3ky5ylg6n2fn39l96fv6rdvsj1g8im6sga37iv8g2bh0l9rmr";
    } {};
  }
