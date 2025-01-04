{
  stdenv,
  callPackage,
  lib,
  makeWrapper,
  git,
  fzf,
  python3,
  nix,
  nixos,
}:

let
  mkUtil =
    name:
    {
      path ? [ ],
      buildInputs ? [ ],
      script ? name,
    }:
    stdenv.mkDerivation {
      inherit name;

      buildInputs = [
        makeWrapper
      ] ++ buildInputs;

      dontUnpack = true;

      installPhase =
        ''
          mkdir -p "$out/bin"
          cp \
            "${./. + "/${script}"}" \
            "$out/bin/${name}"
        ''
        + lib.optionalString (builtins.length path > 0) ''
          # Move to a subdirectory to preserve argv[0]
          mkdir "$out/bin/.wrapped"
          mv \
            "$out/bin/${name}" \
            "$out/bin/.wrapped/${name}"
          makeWrapper \
            "$out/bin/.wrapped/${name}" \
            "$out/bin/${name}" \
            --prefix PATH : "${lib.makeBinPath path}"
        '';
    };
in
{
  deploy = mkUtil "deploy" {
    buildInputs = [
      python3
    ];
    path = [
      nix
      ((nixos { }).nixos-rebuild)
    ];
  };

  deploy-pages = mkUtil "deploy-pages" {
    buildInputs = [
      (python3.withPackages (pp: [
        pp.humanize
        pp.requests
      ]))
    ];
    path = [
      nix
      git
    ];
  };

  git-part-pick = mkUtil "git-part-pick" { path = [ fzf ]; };
  git-auto-fixup = mkUtil "git-auto-fixup" { };
  git-auto-squash = mkUtil "git-auto-squash" { script = "git-auto-fixup"; };
  nix-explore-closure-size = mkUtil "nix-explore-closure-size" { path = [ fzf ]; };
  nopt = callPackage ./nopt { };
  update = mkUtil "update" { buildInputs = [ python3 ]; };
  sman = mkUtil "sman" { path = [ fzf ]; };
  strip-clip-path-transforms = callPackage ./strip-clip-path-transforms { };
}
