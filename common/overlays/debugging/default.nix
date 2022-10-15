final: prev: {
  gnome = prev.gnome.overrideScope' (gfinal: gprev: {
    gnome-control-center = gprev.gnome-control-center.overrideAttrs (attrs: {
      separateDebugInfo = true;
    });
  });
}
