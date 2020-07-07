{ stdenv
, lib
, makeWrapper
, fzf
, python3
}:
let
  mkUtil = name: { path ? [], buildInputs ? [], script ? name }: stdenv.mkDerivation {
    inherit name;

    buildInputs = [
      makeWrapper
    ] ++ buildInputs;

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
    '' + (if builtins.length path > 0 then ''
      makeWrapper \
        ${./. + "/${script}"} \
        $out/bin/${name} \
        --prefix PATH : ${lib.makeBinPath path}
    '' else ''
      cp \
        ${./. + "/${script}"} \
        $out/bin/${name}
    '');
  };
in {
  git-part-pick = mkUtil "git-part-pick" { path = [ fzf ]; };
  git-auto-fixup = mkUtil "git-auto-fixup" { };
  git-auto-squash = mkUtil "git-auto-squash" { script = "git-auto-fixup"; };
  nix-explore-closure-size = mkUtil "nix-explore-closure-size" { path = [ fzf ]; };
  rebuild = mkUtil "rebuild" { buildInputs = [ python3 ]; };
  sman = mkUtil "sman" { path = [ fzf ]; };
}
