{ fetchFromGitHub }:

fetchFromGitHub (builtins.fromJSON (builtins.readFile ./src.json))
