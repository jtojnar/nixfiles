{
  symlinkJoin,
  lib,
  callPackage,
  runCommand,
  writeText,
}:

let
  flarum = callPackage ./flarum.nix { };

  /* Translate a simple Nix expression to PHP notation.
  */
  toPhp = { indent ? "", indentStyle ? "  ", indentFirst ? true }@args: v:
    let
      concatItems = lib.concatMapStrings (item: item + ",\n");
    in
    lib.optionalString indentFirst indent
    + (
      if builtins.isAttrs v then
        "[\n"
        + concatItems
            (lib.mapAttrsToList
              (key: value: "${indent + indentStyle}${builtins.toJSON key} => ${toPhp (args // { indent = indent + indentStyle; indentFirst = false; }) value}")
              v
            )
        + indent
        + "]"
      else if builtins.isList v then
        "[\n"
        + concatItems (map (toPhp (args // { indent = indent + indentStyle; indentFirst = true; })) v)
        + indent
        + "]"
      else if builtins.isInt v then
        "${toString v}"
      else if builtins.isBool v then
        (if v then "true" else "false")
      else if builtins.isFunction v then
        abort "generators.toPhp: cannot convert a function to PHP"
      else if v == null then
        "null"
      else
        builtins.toJSON v
    );

  # Symlinks to mutable directories for paths flarum will want to write to.
  mutablePathSymlinks =
    {
      stateDir,
      config,
    }:

    let
      configFile = writeText "config.php" ''
        <?php
        return ${toPhp {} config};
      '';
    in

    runCommand "mutable-flarum-paths" { } ''
      for d in public/assets ${lib.optionalString (config == null) "config.php"}; do
          mkdir -p "$(dirname "$out/$d")"
          ln -s "${stateDir}/$d" "$out/$d"
      done

      ${lib.optionalString (config != null) "cp '${configFile}' \"$out/config.php\""}
    '';

  buildTree =
    {
      enableInstaller ? false,
      unitName ? "flarum",
      stateDir ? "/var/lib/${unitName}",
      enabledPackages ? [ ],
      config ? null,
    }@args:

    symlinkJoin {
      name = "${unitName}-combined";

      paths = [
        flarum
        (mutablePathSymlinks { inherit stateDir config; })
      ] ++ enabledPackages;

      postBuild = ''
        # Materialize files so that PHP’s __DIR__ constant refers to the combined tree.
        for f in flarum site.php; do
            original="$(readlink -f "$out/$f")"
            rm "$out/$f"
            cp "$original" "$out/$f"
        done
      '';

      passthru = {
        withConfig = newArgs: buildTree (args // newArgs);
        inherit flarum;
        inherit stateDir;
      };
    };
in

buildTree { }
