#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=channel:nixos-unstable -p curl -p nodePackages.node2nix -p nix-prefetch-github -i bash
set -o errexit

srcDir="$(dirname "${BASH_SOURCE[0]}")"

# nix-prefetch-github needs <nixpkgs>
# https://github.com/seppeljordan/nix-prefetch-github/issues/31#issuecomment-655673145
env NIX_PATH="nixpkgs=channel:nixos-unstable" nix-prefetch-github jtojnar wrcq > $srcDir/src.json
platform=$(nix-instantiate --eval --json -E 'builtins.currentSystem')
src=$(nix-build --no-out-link -A "outputs.packages.${platform}.wrcq.src")
cd $srcDir/source
node2nix --nodejs-12 -i $src/package.json -l $src/package-lock.json
sed --regexp-extended --in-place 's#src = (\.\./)+nix/store/.+;#src = import ../src.nix { inherit fetchFromGitHub; };#g' node-packages.nix
sed --regexp-extended --in-place 's#fetchurl, fetchgit, #fetchurl, fetchgit, fetchFromGitHub, #g' node-packages.nix
sed --regexp-extended --in-place 's#inherit \(pkgs\) fetchurl fetchgit#inherit (pkgs) fetchurl fetchgit fetchFromGitHub#g' default.nix
