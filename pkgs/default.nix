final: prev: {
  adminer-with-plugins = prev.callPackage ./adminer { };

  flarum = prev.callPackage ./flarum { };

  flarum-webhooks-telegram-bridge = prev.callPackage ./flarum-webhooks-telegram-bridge { };

  pechar = prev.callPackage ./pechar { };

  pengu = prev.callPackage ./pengu { };

  phpbb = prev.callPackage ./phpbb { };

  selfoss = prev.callPackage ./selfoss { };

  sunflower = prev.callPackage ./sunflower { };

  transmission_3-gtk = prev.callPackage ./transmission_3-gtk { };

  wrcq = prev.callPackage ./wrcq { };

  inherit (prev.callPackages ./utils { })
    deploy
    deploy-pages
    git-part-pick
    git-auto-fixup
    git-auto-squash
    nix-explore-closure-size
    nopt
    update
    sman
    strip-clip-path-transforms
    ;
}
