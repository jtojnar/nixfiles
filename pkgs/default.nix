final: prev: {
  inherit (prev.callPackages ./activitywatch { })
    aw-server-rust;

  pengu = prev.callPackage ./pengu {};

  phpbb = prev.callPackage ./phpbb {};

  selfoss = prev.callPackage ./selfoss {};

  inherit (prev.recurseIntoAttrs (prev.callPackage ./sublime4/packages.nix { }))
    sublime4-dev;

  sunflower = prev.callPackage ./sunflower {};

  vikunja-api = prev.callPackage ./vikunja/vikunja-api {};

  vikunja-frontend = prev.callPackage ./vikunja/vikunja-frontend {};

  wrcq = prev.callPackage ./wrcq {};

  inherit (prev.callPackages ./utils {})
    deploy
    git-part-pick
    git-auto-fixup
    git-auto-squash
    nix-explore-closure-size
    update
    sman;
}
