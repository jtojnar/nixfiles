{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4091";
      dev = true;
      x64sha256 = "1mxgylxmd2bl77pr24c256dr3l21miav1gfmafvp2bay4xa6s4ws";
      aarch64sha256 = "05j1ll3qxq6yl2r0bh9hp11rpywvkmg6j89p4wyhmrz10asaqd0s";
    } {};
  }
