{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4104";
      dev = true;
      x64sha256 = "19cd48wkzfi8dvsgwyzz4fjipqf3bg57v54l1an5wy02i53ff1l4";
      aarch64sha256 = "14fr0mabl5vikrljrgyiqa6qi7nhlp472q8x45nmnqkhypc3nsw5";
    } {};
  }
