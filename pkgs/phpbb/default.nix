{ symlinkJoin
, lib
, callPackage
, runCommand
}:

let
  packages = {
    langs = {
      cs = callPackage ./langs/cs.nix { };
    };
  };

  phpbb = callPackage ./core.nix { };

  # Symlinks to mutable directories for paths phpBB will want to write to.
  mutablePathSymlinks = {
    stateDir,
    cacheDir,
  }: runCommand "mutable-phpbb-paths" { } ''
    for d in store files images/avatars/upload config.php; do
        mkdir -p "$(dirname "$out/$d")"
        ln -s "${stateDir}/$d" "$out/$d"
    done

    ln -s "${cacheDir}" "$out/cache"
  '';

  buildTree = {
    enableInstaller ? false,
    unitName ? "phpbb",
    stateDir ? "/var/run/${unitName}",
    enabledPackages ? [ ],
    cacheDir ? "/var/cache/${unitName}",
  }@args: symlinkJoin {
    name = "${unitName}-combined";

    paths = [
      phpbb
      (mutablePathSymlinks { inherit stateDir cacheDir; })
    ] ++ lib.optionals enableInstaller [
      phpbb.installer
    ] ++ enabledPackages;

    passthru = {
      withConfig = newArgs: buildTree (args // newArgs);

      core = phpbb;
      inherit stateDir cacheDir packages;
    };
  };
in

buildTree { }
