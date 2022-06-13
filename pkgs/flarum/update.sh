#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=channel:nixos-unstable -i bash -p common-updater-scripts curl jq php.packages.composer

set -euo pipefail

owner=flarum
repo=flarum
latestVersion=$(curl "https://api.github.com/repos/$owner/$repo/releases/latest" | jq --raw-output '.tag_name | sub("^v"; "")')
currentVersion=$(nix-instantiate --eval --json --expr 'with import ./. {}; flarum.flarum.version' | jq --raw-output '.')

if [[ "$currentVersion" == "$latestVersion" && "${BUMP_LOCK-}" != "1" ]]; then
    # Skip update when already on the latest version.
    exit 0
fi

update-source-version flarum.flarum "$latestVersion"

repoSelf="$(nix eval -f . --json 'outPath' | jq --raw-output '.')"
# Flakes might place the file into store so we need to switch it back to source tree.
# Assuming PWD is repository root.
dirname="$(realpath --relative-to="$repoSelf" "$(dirname "$0")")"
sourceDir="$(nix-build -A flarum.flarum.src --no-out-link)"
tempDir="$(mktemp -d)"

pushd "$tempDir"

cp -r "$sourceDir"/* "$tempDir"
chmod -R +w "$tempDir"

composer install

composer require flarum/akismet
composer require fof/formatting
composer require fof/links
composer require fof/oauth
composer require fof/secure-https
composer require fof/upload
composer require fof/user-directory
composer require fof/webhooks
composer require ianm/syndication
composer require ianm/synopsis
composer require madnest/flarum-lang-czech
composer require xelson/flarum-ext-chat

popd

cp -r "$tempDir/composer.json" "$dirname"
cp -r "$tempDir/composer.lock" "$dirname"
