{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4096";
      dev = true;
      x64sha256 = "16c6sdaw7n3949i499kpcq9p1qiq29xhdsr21l5rqm241gm09pk5";
      aarch64sha256 = "0qgi9xcz2pbjzvjfmpa1ni7r9hq8f0zh0hb6slnn73r9mgahq8lc";
    } {};
  }
