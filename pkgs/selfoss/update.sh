#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=channel:nixos-unstable -p curl -p common-updater-scripts -p jq -i bash
latest_version=$(curl https://dl.cloudsmith.io/public/fossar/selfoss-git/raw/index.json | jq '.packages | max_by(.upload_date) | .version' --raw-output)
update-source-version selfoss "$latest_version"
