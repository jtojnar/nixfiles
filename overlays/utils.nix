(self: super: let
  mkUtil = name: { path ? [], script ? name }: super.stdenv.mkDerivation {
    inherit name;

    buildInputs = [ super.makeWrapper ];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
    '' + (if builtins.length path > 0 then ''
      makeWrapper \
        ${./. + "/utils/${script}"} \
        $out/bin/${name} \
        --prefix PATH : ${super.lib.makeBinPath path}
    '' else ''
      cp \
        ${./. + "/utils/${script}"} \
        $out/bin/${name}
    '');
  };
in with super; {
  git-part-pick = mkUtil "git-part-pick" { path = [ fzf ]; };
  git-auto-fixup = mkUtil "git-auto-fixup" { };
  git-auto-squash = mkUtil "git-auto-squash" { script = "git-auto-fixup"; };
  sman = mkUtil "sman" { path = [ fzf ]; };
})
