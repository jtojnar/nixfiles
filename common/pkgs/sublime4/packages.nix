{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4084";
      dev = true;
      x64sha256 = "JVAM70NU3ioi2Z9gu/y9NhAqdA+m6dCLD9MapnJ61Dg=";
      aarch64sha256 = "mtqbr81ZmcICEPq98Fu46aMAE6nm8PkN8+lFRoonsbE=";
    } {};
  }
