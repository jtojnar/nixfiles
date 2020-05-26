self: super: {
  selfoss = super.callPackage ./selfoss {};

  vikunja-api = super.callPackage ./vikunja/vikunja-api {};

  vikunja-frontend = super.callPackage ./vikunja/vikunja-frontend {};

  inherit (super.callPackages ./utils {})
    git-part-pick
    git-auto-fixup
    git-auto-squash
    nix-explore-closure-size
    sman;
}
