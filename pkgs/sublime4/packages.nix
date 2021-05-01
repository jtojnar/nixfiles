{ callPackage }:

let
  common = opts: callPackage (import ./common.nix opts);
in
  {
    sublime4-dev = common {
      buildVersion = "4103";
      dev = true;
      x64sha256 = "0cvbj5dkfsyalvg3waik9yfa1gv1xap8aym90p4k6zyayn05k766";
      aarch64sha256 = "0ci8n7smppjcdafgyws7ldwvhvp45s9f8vwjr6cwf85lh3nhxhzd";
    } {};
  }
