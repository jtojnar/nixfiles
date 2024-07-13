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
scriptSelf="$(nix eval -f . --json 'flarum.flarum.passthru.updateScript' | jq --raw-output '.')"
# Flakes might place the file into Nix store so we need to switch it back to the source tree.
# This script will be run from the repository root so we need to make it relative to that.
dirname="$(realpath --relative-to="$repoSelf" "$(dirname "$scriptSelf")")"
sourceDir="$(nix-build -A flarum.flarum.src --no-out-link)"
tempDir="$(mktemp -d)"

pushd "$tempDir"

# These steps are equivalent to `composer create-project flarum/flarum .`
# used in the official CLI installation instructions:
# https://docs.flarum.org/install/#installing-using-the-command-line-interface
cp -r "$sourceDir"/* "$tempDir"
chmod -R +w "$tempDir"
composer install

# Install select extensions.
# Kept in the same package so that Composer manages the dependency hell.
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

# Persist the “source of truth” for the currently installed version.
cp "$tempDir/composer.json" "$dirname"
cp "$tempDir/composer.lock" "$dirname"

# Update FOD in the package.
update-source-version flarum.flarum "$latestVersion" --ignore-same-version --source-key=composerRepository
