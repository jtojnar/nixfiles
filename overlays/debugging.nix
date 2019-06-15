(self: super: {
  deadbeef = super.enableDebugging super.deadbeef;
  deadbeefPlugins = builtins.mapAttrs (name: plugin: super.enableDebugging plugin) super.deadbeefPlugins;

  gnome3 = super.gnome3.overrideScope' (gself: gsuper: {
    geary = super.enableDebugging gsuper.geary;

    polari = super.enableDebugging (gsuper.polari.override {
      gjs = super.enableDebugging gsuper.gjs;
    });

    rygel = super.enableDebugging (gsuper.rygel.override {
      tracker = super.enableDebugging (gsuper.tracker.overrideAttrs (attrs: {
        mesonBuildType = "debug";
      }));
    });
  });
})
