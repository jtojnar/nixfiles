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
, gnome
, gobject-introspection
, wrapGAppsHook
}:

python3.pkgs.buildPythonApplication rec {
  pname = "sunflower";
  version = "2020-10-12-unstable";

  src = fetchFromGitHub {
    owner = "MeanEYE";
    repo = "Sunflower";
    rev = "8d75084e78f82276a13b51bd10fa9ae4fbae18f4";
    sha256 = "jAh26yjNRZOIt++geWb7geVOdHpNhxlYhOiEiFTCtSg=";
  };

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook
  ];

  buildInputs = [
    glib
    gtk3
    libnotify
    vte
    gvfs
    gsettings-desktop-schemas # for font settings
    gnome.libgnome-keyring
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

  meta = with lib; {
    description = "Small and highly customizable twin-panel file manager for Linux with support for plugins";
    homepage = "https://sunflower-fm.org/";
    license = licenses.gpl3;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
