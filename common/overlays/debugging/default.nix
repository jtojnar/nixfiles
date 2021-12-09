final: prev: {
  gnome = prev.gnome.overrideScope' (gfinal: gprev: {
    gnome-control-center = gprev.gnome-control-center.overrideAttrs (attrs: {
      separateDebugInfo = true;
    });
    gnome-shell = gprev.gnome-shell.overrideAttrs (attrs: {
      separateDebugInfo = true;
    });
    mutter = gprev.mutter.overrideAttrs (attrs: {
      separateDebugInfo = true;
    });
  });
}
