#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=channel:nixos-unstable -p curl -p common-updater-scripts -p jq -i bash
latest_version=$(curl https://api.bintray.com/packages/fossar/selfoss/selfoss-git | jq .latest_version --raw-output)
update-source-version selfoss "$latest_version"
