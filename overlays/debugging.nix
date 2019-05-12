(self: super: {
  deadbeef = super.enableDebugging super.deadbeef;
  deadbeefPlugins.headerbar-gtk3 = super.enableDebugging super.deadbeefPlugins.headerbar-gtk3;
  deadbeefPlugins.infobar = super.enableDebugging super.deadbeefPlugins.infobar;
  deadbeefPlugins.mpris2 = super.enableDebugging super.deadbeefPlugins.mpris2;

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
