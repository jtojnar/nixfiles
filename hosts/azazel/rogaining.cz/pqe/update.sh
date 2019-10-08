#!/usr/bin/env nix-shell
#!nix-shell -p curl -p nodePackages.node2nix -p nix-prefetch-github -i bash
nix-prefetch-github jtojnar wrcq > src.json
src=$(nix-build --no-out-link -E '(with import <nixpkgs> {}; callPackage ./src.nix { })')
cd source
node2nix --nodejs-12 -i $src/package.json -l $src/package-lock.json
sed --regexp-extended --in-place 's#src = (\.\./)+nix/store/.+;#src = import ../src.nix { inherit fetchFromGitHub; };#g' node-packages.nix
sed --regexp-extended --in-place 's#fetchurl, fetchgit, #fetchurl, fetchgit, fetchFromGitHub, #g' node-packages.nix
sed --regexp-extended --in-place 's#inherit \(pkgs\) fetchurl fetchgit#inherit (pkgs) fetchurl fetchgit fetchFromGitHub#g' default.nix
