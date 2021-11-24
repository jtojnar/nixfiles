final: prev: {
  gnome3 = prev.gnome3.overrideScope' (gself: gsuper: {
    gnome-control-center = gsuper.gnome-control-center.overrideAttrs (attrs: {
      separateDebugInfo = true;
    });
    gnome-shell = gsuper.gnome-shell.overrideAttrs (attrs: {
      separateDebugInfo = true;
    });
    mutter = gsuper.mutter.overrideAttrs (attrs: {
      separateDebugInfo = true;
    });
  });
}
