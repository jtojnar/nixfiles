{
  lib,
  adminer,
  runCommand,
  writeTextFile,

  plugins ? [ ],
  theme ? null,
  pluginConfigs ? "",
  customStyle ? null,
  customCommands ? null,
}:

let
  package = adminer.overrideAttrs (attrs: {
    postInstall =
      attrs.postInstall or ""
      + ''
        cp -r plugins "$out"
      ''
      + lib.optionalString (theme != null) ''
        if [[ ! -f "designs/${theme}/adminer.css" ]]; then
            echo "Theme ${theme} does not exist." > /dev/stderr
            exit 1
        fi
        cp "designs/${theme}/adminer.css" "$out/${theme}.css"
      '';
  });

  pluginConfigPhp = writeTextFile {
    name = "adminer-plugins.php";
    text = ''
      <?php

      return [
        ${pluginConfigs}
      ];
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

runCommand "adminer-with-plugins"
  {
    adminer = package;
  }
  (
    ''
      mkdir -p "$out"
      ln -s "${package}/adminer.php" "$out/index.php"

      ${lib.optionalString (plugins != [ ]) ''
        mkdir -p "$out/adminer-plugins"
        ${lib.concatMapStringsSep "\n" (plugin: ''
          if [[ ! -f "${package}/plugins/${plugin}.php" ]]; then
              echo "Plug-in ${plugin} does not exist." > /dev/stderr
              exit 1
          fi
          ln -s "${package}/plugins/${plugin}.php" "$out/adminer-plugins"
        '') plugins}
      ''}

      ln -s "${
        if pluginConfigs != "" then pluginConfigPhp else "${package}/adminer.php"
      }" "$out/adminer-plugins.php"
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
