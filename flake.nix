{
  description = "jtojnar’s machines";

  inputs = {
    # Shim to make flake.nix work with stable Nix.
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    napalm = {
      url = "github:nmattia/napalm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:guibou/nixGL";
      flake = false;
    };

    nixpkgs-mozilla = {
      # https://github.com/mozilla/nixpkgs-mozilla/pull/250
      url = "github:andersk/nixpkgs-mozilla/stdenv.lib";
      flake = false;
    };
  };

  outputs = { self, flake-compat, naersk, napalm, nixpkgs, nixpkgs-mozilla, nixgl }@inputs:
    let
      inherit (nixpkgs) lib;

      # Flakes require ‘packages’ attribute to contain per-platform attrsets.
      # Here we explicitly define all the platforms that will be exposed.
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllPlatforms = f: lib.genAttrs platforms (platform: f platform);

      # Generate an attribute set by mapping a function over a list of values.
      genAttrs' = values: f: builtins.listToAttrs (map f values);

      # Convert a list to file paths to attribute set
      # that has the filenames stripped of nix extension as keys
      # and imported content of the file as value.
      pathsToImportedAttrs = paths:
        genAttrs' paths (path: {
          name = lib.removeSuffix ".nix" (builtins.baseNameOf path);
          value = import path;
        });

      # Create combined package set from nixpkgs and our overlays.
      mkPkgs = platform: import nixpkgs {
        system = platform;
        overlays = builtins.attrValues self.overlays ++ [
          # Take only napalm attribute from napalm overlay and
          # pass it the latest nodejs.
          (lib.pipe napalm.overlay [
            (locallyOverrideFinal (final: { nodejs = final.nodejs_latest; }))
            (filterOverlayAttrs [ "napalm" ])
          ])

          (final: prev: {
            naerskUnstable =
              let
                nmo = import nixpkgs-mozilla final prev;
                rust = (nmo.rustChannelOf {
                  date = "2021-01-27";
                  channel = "nightly";
                  sha256 = "447SQnx5OrZVv6Na5xbhiWoaCwIUrB1KskyMOQEDJb8=";
                }).rust;
              in
                naersk.lib.${platform}.override {
                  cargo = rust;
                  rustc = rust;
                };
          })
        ];
        config = {
          allowUnfree = true;
          allowAliases = false;
        };
      };

      # We should not trust overlays to override arbitrary attribute paths.
      # Let’s keep only those whitlelisted in the first attribute.
      filterOverlayAttrs = attrs: overlay: final: prev: builtins.intersectAttrs (lib.genAttrs attrs (attr: null)) (overlay final prev);

      # If a package from overlay depends on some final package, let’s change it into a different one.
      locallyOverrideFinal = mkAttrs: overlay: final: prev: overlay (final // mkAttrs final) prev;

      # Package sets for each platform.
      pkgss = forAllPlatforms mkPkgs;
    in {
      # Configurations for our hosts.
      # These are used by tools like nixos-rebuild.
      nixosConfigurations =
        let
          configs = import ./hosts { inherit inputs pkgss; };
        in configs;

      # Environments for nix-env.
      # These are used by nix-deploy-profile tool defined below.
      nixEnvEnvironments =
        let
          envs = {
            brian = {
              platform = "x86_64-linux";
            };
          };
        in
          builtins.mapAttrs (
            hostName:
            { platform }:
              import (./hosts + "/${hostName}/profile.nix") {
                inherit inputs lib;
                pkgs = pkgss.${platform};
              }
          ) envs;

      # Overlay containing our packages defined in this repository.
      overlay = import ./pkgs;

      # All our overlays.
      # We will apply them to all hosts.
      overlays =
        let
          overlayDir = ./common/overlays;
          fullPath = name: overlayDir + "/${name}";
          overlayPaths = map fullPath (builtins.attrNames (builtins.readDir overlayDir));
        in pathsToImportedAttrs overlayPaths;

      # All our packages listed in /pkgs.
      packages =
        let
          # We only have our packages listed in an overlay so we need to extract them from there.
          packageAttributes = builtins.attrNames (self.overlay null null);
        in
          forAllPlatforms (platform: lib.getAttrs packageAttributes pkgss.${platform});

      # All our modules and profiles that can be imported.
      # A module in /common/modules/baz/qux.nix can be accessed as ‘${flakeRef}.nixosModules.qux’
      # A profile in /common/profiles/foo.nix can be accessed as ‘${flakeRef}.nixosModules.profiles.foo’
      nixosModules =
        let
          modulesAttrs = pathsToImportedAttrs (import ./common/modules/list.nix);

          profilesAttrs = {
            profiles = pathsToImportedAttrs (import ./common/profiles/list.nix);
          };
        in modulesAttrs // profilesAttrs;

      # Development shell containing our maintenance utils
      devShell = forAllPlatforms (platform:
        pkgss.${platform}.mkShell {
          nativeBuildInputs = with pkgss.${platform}; [
            deploy
            git
            git-crypt
            nixUnstable
            update
            (writeShellScriptBin "deploy-nix-profile" ''
              nix-env -f . -E 'flake: flake.nixEnvEnvironments.'"$(hostname)" --remove-all --install
            '')
          ];

          # Enable flakes even though they are optional
          NIX_CONF_DIR = let
            current = pkgss.${platform}.lib.optionalString (builtins.pathExists /etc/nix/nix.conf)
              (builtins.readFile /etc/nix/nix.conf);

            nixConf = pkgss.${platform}.writeTextDir "opt/nix.conf" ''
              ${current}
              experimental-features = nix-command flakes ca-references
            '';
          in "${nixConf}/opt";
        }
      );
    };
}
