final: prev: {
  adminer-with-plugins = prev.callPackage ./adminer {};

  inherit (prev.callPackages ./activitywatch { })
    aw-core
    aw-client
    aw-server-rust
    aw-qt
    aw-watcher-afk
    aw-watcher-window
    aw-webui;

  flarum = prev.callPackage ./flarum {};

  flarum-webhooks-telegram-bridge = prev.callPackage ./flarum-webhooks-telegram-bridge {};

  pechar = prev.callPackage ./pechar {};

  pengu = prev.callPackage ./pengu {};

  phpbb = prev.callPackage ./phpbb {};

  selfoss = prev.callPackage ./selfoss {};

  sunflower = prev.callPackage ./sunflower {};

  wrcq = prev.callPackage ./wrcq {};

  inherit (prev.callPackages ./utils {})
    deploy
    git-part-pick
    git-auto-fixup
    git-auto-squash
    nix-explore-closure-size
    nopt
    update
    sman
    strip-clip-path-transforms;
}
