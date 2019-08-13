(self: super: {
  gnome3 = super.gnome3.overrideScope' (gself: gsuper: {
    geary = super.enableDebugging gsuper.geary;

    polari = super.enableDebugging (gsuper.polari.override {
      gjs = super.enableDebugging gsuper.gjs;
    });
  });
})
