(self: super: let
  mkUtil = name: path: super.stdenv.mkDerivation {
    inherit name;

    buildInputs = [ super.makeWrapper ];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp ${./utils}/${name} $out/bin

      for f in $out/bin/*; do
        wrapProgram $f --prefix PATH : ${super.lib.makeBinPath path}
      done
    '';
  };
in with super; {
  git-part-pick = mkUtil "git-part-pick" [ fzf ];
  git-auto-fixup = mkUtil "git-auto-fixup" [ ];
})
