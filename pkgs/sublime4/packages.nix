{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4094";
      dev = true;
      x64sha256 = "0i566aqk11hwgm31c0pycr68rp0hhyspc1rynhs6b8gc1j1ql9r6";
      aarch64sha256 = "0448rg92jb5nf8aaag649pzigrxki63878yx4car4sivapdw3bz0";
    } {};
  }
