(self: super: let
  mkUtil = name: path: super.stdenv.mkDerivation {
    inherit name;

    buildInputs = [ super.makeWrapper ];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin

      makeWrapper \
        ${./. + "/utils/${name}"} \
        $out/bin/${name} \
        --prefix PATH : ${super.lib.makeBinPath path}
    '';
  };
in with super; {
  git-part-pick = mkUtil "git-part-pick" [ fzf ];
  git-auto-fixup = mkUtil "git-auto-fixup" [ ];
  sman = mkUtil "sman" [ fzf ];
})
