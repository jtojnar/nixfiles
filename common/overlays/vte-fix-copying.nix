final: prev: {
  gnome = prev.gnome.overrideScope (gfinal: gprev: {
    gnome-terminal = gprev.gnome-terminal.override {
      vte = prev.vte.overrideAttrs (attrs: {
        patches = attrs.patches or [] ++ [
          # Fix copying all terminal text.
          # https://gitlab.gnome.org/GNOME/gnome-terminal/issues/288
          (prev.fetchpatch {
            url = "https://gitlab.gnome.org/GNOME/vte/commit/73713ec0644e232fb740170e399282be778d97f9.patch";
            sha256 = "xES6Oain9I8A/5uEXws4XJKthwyE64HoInAtAsDs7p0=";
            revert = true;
          })
        ];
      });
    };
  });
}
