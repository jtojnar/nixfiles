{
  lib,
  adminerevo,
  runCommand,
  writeTextFile,

  plugins ? [ ],
  theme ? null,
  pluginConfigs ? "",
  customStyle ? null,
  customCommands ? null,
}:

let
  package = adminerevo.overrideAttrs (attrs: {
    postInstall =
      attrs.postInstall or ""
      + lib.optionalString (plugins != [ ]) ''
        mkdir -p "$out/plugins"
        cp "plugins/plugin.php" "$out/plugins"
        ${lib.concatMapStringsSep "\n" (plugin: ''
          if [[ ! -f "plugins/${plugin}.php" ]]; then
              echo "Plug-in ${plugin} does not exist." > /dev/stderr
              exit 1
          fi
          cp "plugins/${plugin}.php" "$out/plugins"
        '') plugins}
      ''
      + lib.optionalString (theme != null) ''
        if [[ ! -f "designs/${theme}/adminer.css" ]]; then
            echo "Theme ${theme} does not exist." > /dev/stderr
            exit 1
        fi
        cp "designs/${theme}/adminer.css" "$out/${theme}.css"
      '';
  });

  entrypoint = writeTextFile {
    name = "index.php";
    text = ''
      <?php

      function adminer_object() {
        // required to run any plugin
        require_once '${package}/plugins/plugin.php';

        // autoloader
        foreach (glob('${package}/plugins/*.php') as $filename) {
          require_once $filename;
        }

        $plugins = [
          // specify enabled plugins here
          ${pluginConfigs}
        ];

        return new AdminerPlugin($plugins);
      }

      // include original Adminer or Adminer Editor
      require '${package}/adminer.php';
    '';
  };

  style = writeTextFile {
    name = "adminer.css";
    text = ''
      @import "${theme}.css";
      ${if builtins.isPath customStyle then builtins.readFile customStyle else customStyle}
    '';
  };
in

# If we want to use otp plug-in, we cannot have adminer.php accessible since that does not load plug-ins and would allow bypassing the otp plug-in.
runCommand "adminer-with-plugins"
  {
    adminer = package;
  }
  (
    ''
      mkdir -p "$out"
      ln -s "${if plugins != [ ] then entrypoint else "${package}/adminer.php"}" "$out/index.php"
    ''
    + lib.optionalString (theme != null) ''
      ln -s "${package}/${theme}.css" "$out/${if customStyle != null then theme else "adminer"}.css"
    ''
    +
      lib.optionalString
        (
          assert customStyle != null -> theme != null;
          customStyle != null
        )
        ''
          ln -s "${style}" "$out/adminer.css"
        ''
    + lib.optionalString (customCommands != null) customCommands
  )
