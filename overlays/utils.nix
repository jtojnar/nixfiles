(self: super: let
  mkUtil = name: { path ? [], script ? name }: super.stdenv.mkDerivation {
    inherit name;

    buildInputs = [ super.makeWrapper ];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin

      makeWrapper \
        ${./. + "/utils/${script}"} \
        $out/bin/${name} \
        --prefix PATH : ${super.lib.makeBinPath path}
    '';
  };
in with super; {
  git-part-pick = mkUtil "git-part-pick" { path = [ fzf ]; };
  git-auto-fixup = mkUtil "git-auto-fixup" { };
  sman = mkUtil "sman" { path = [ fzf ]; };
})
