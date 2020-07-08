final: prev: {
  selfoss = prev.callPackage ./selfoss {};

  vikunja-api = prev.callPackage ./vikunja/vikunja-api {};

  vikunja-frontend = prev.callPackage ./vikunja/vikunja-frontend {};

  wrcq = prev.callPackage ./wrcq {};

  inherit (prev.callPackages ./utils {})
    git-part-pick
    git-auto-fixup
    git-auto-squash
    nix-explore-closure-size
    rebuild
    update
    sman;
}
