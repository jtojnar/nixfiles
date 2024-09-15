{ python3
, lib
, fetchFromGitHub
, fetchpatch
, gtk3
, glib
, libnotify
, vte
, gvfs
, gsettings-desktop-schemas
, libgnome-keyring
, gobject-introspection
, wrapGAppsHook3
, unstableGitUpdater
}:

python3.pkgs.buildPythonApplication rec {
  pname = "sunflower";
  version = "unstable-2022-04-26";

  src = fetchFromGitHub {
    owner = "MeanEYE";
    repo = "Sunflower";
    rev = "7062a640ffbb016ce317c5c9b4cc39e9ad8a71b4";
    sha256 = "yhXsM6tWbXyGD+7ANiHLMLvwe8Wax6uFytE0QsB8fkk=";
  };

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook3
  ];

  buildInputs = [
    glib
    gtk3
    libnotify
    vte
    gvfs
    gsettings-desktop-schemas # for font settings
    libgnome-keyring
  ];

  propagatedBuildInputs = [
    python3.pkgs.pygobject3
    python3.pkgs.chardet
  ];

  # See https://github.com/NixOS/nixpkgs/issues/56943
  strictDeps = false;

  # There are no tests.
  doCheck = false;

  postPatch = ''
    # Outside of Nix, Python modules are installed under Python’s prefix
    # or into a virtual environment, that overrides sys.prefix.
    # https://docs.python.org/3/library/sys.html#sys.prefix
    # We do neither so we need to override the variable ourselves.
    echo "import sys; sys.prefix = '${placeholder "out"}'" | cat - sunflower/__init__.py > temp && mv temp sunflower/__init__.py
  '';

  passthru.updateScript = unstableGitUpdater {
    # The updater tries src.url by default, which does not exist for fetchFromGitHub (fetchurl).
    url = "https://github.com/MeanEYE/Sunflower.git";
  };

  meta = with lib; {
    description = "Small and highly customizable twin-panel file manager for Linux with support for plugins";
    homepage = "https://sunflower-fm.org/";
    license = licenses.gpl3Plus;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
