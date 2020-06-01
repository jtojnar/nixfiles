final: prev: {
  gnome3 = prev.gnome3.overrideScope' (gself: gsuper: {
    geary = prev.enableDebugging gsuper.geary;

    polari = prev.enableDebugging (gsuper.polari.override {
      gjs = prev.enableDebugging gsuper.gjs;
    });
  });
}
