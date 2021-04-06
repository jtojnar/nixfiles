{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4101";
      dev = true;
      x64sha256 = "1v7433dl003fs0mpdlz1bd1m8zzgvf2y0yij49kvp9vzsp6xq7j3";
      aarch64sha256 = "1a3dqfm0philvx1vfwnjwf4c04m65q6289frxllkjdr4lshlsvg8";
    } {};
  }
