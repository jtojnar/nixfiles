{ pkgs, ... }:

{
  # Single last selection not available on Package Control.
  # https://github.com/dperdikopoulos/Single-Last-Selection
  home.file.".config/sublime-text/Packages/User/single-last-selection.py".source = pkgs.fetchurl {
    url = "https://github.com/dperdikopoulos/Single-Last-Selection/raw/f1431e6ea693c6c785ad924e21b472e73a73b2e9/single-last-selection.py";
    hash = "sha256-P2yU9hVq8epaa7F0gzFg6uzzZCLg3qskwN/qYjhwR64=";
  };

  home.file.".config/sublime-text/Packages/User/Default.sublime-keymap".text = ''
    [
      {
        "keys": ["shift+escape"],
        "command": "single_last_selection",
        "context": [
          { "key": "num_selections", "operator": "not_equal", "operand": 1 }
        ]
      },

      // Use Ctrl-Tab for switching tabs as they appear in the tab bar rather than LIFO.
      { "keys": ["ctrl+tab"], "command": "next_view" },
      { "keys": ["ctrl+shift+tab"], "command": "prev_view" },
      { "keys": ["ctrl+pagedown"], "command": "next_view_in_stack" },
      { "keys": ["ctrl+pageup"], "command": "prev_view_in_stack" },
    ]
  '';
}
