{
  description = "jtojnar’s machines";

  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    c4 = {
      url = "github:fossar/composition-c4";
    };

    dwarffs = {
      url = "github:edolstra/dwarffs";
      inputs.nixpkgs.follows = "nixpkgs";
      # HACK: Prevent adding a second nixpkgs copy.
      # `inputs.nix.inputs.nixpkgs.follows = "nixpkgs";` does not seem to help
      # so let’s just replace the nix input with a dummy input.
      # Fortunately, we only use overlays, which do not depend on any inputs.
      inputs.nix.follows = "nixpkgs";
    };

    # Shim to make flake.nix work with stable Nix.
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    napalm = {
      url = "github:nix-community/napalm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:guibou/nixGL";
      flake = false;
    };

    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = { self, agenix, c4, dwarffs, flake-compat, home-manager, naersk, napalm, nixpkgs, nixpkgs-mozilla, nixgl }@inputs:
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
          c4.overlays.default

          # Take only dwarffs attribute from dwarffs overlay and
          # pass it unstable Nix.
          (lib.pipe dwarffs.overlay [
            (filterOverlayAttrs [ "dwarffs" ])
          ])

          # Take only napalm attribute from napalm overlay and
          # pass it the latest nodejs.
          (lib.pipe napalm.overlay [
            (locallyOverrideFinal (final: { nodejs = final.nodejs_latest; }))
            (filterOverlayAttrs [ "napalm" ])
          ])

          (final: prev: {
            home-manager = prev.callPackage "${home-manager}/home-manager" { };

            naerskUnstable =
              let
                nmo = import nixpkgs-mozilla final prev;
                rust = (nmo.rustChannelOf {
                  date = "2021-06-30";
                  channel = "nightly";
                  sha256 = "d02mYpeoCuv+tf2oFUOGybJ23GzcA9pSyJT8z/7RuSg=";
                }).rust;
              in
                naersk.lib.${platform}.override {
                  cargo = rust;
                  rustc = rust;
                };

            nixgl = import nixgl { pkgs = prev; };
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
      homeConfigurations =
        let
          envs = {
            brian = {
              platform = "x86_64-linux";
              user = "jtojnar";
            };
          };
        in
          builtins.mapAttrs (
            hostName:
            {
              platform,
              user,
            }:

            home-manager.lib.homeManagerConfiguration {
              pkgs = pkgss.${platform};

              modules = [
                (./hosts + "/${hostName}/home.nix")

                {
                  home = {
                    homeDirectory = "/home/${user}";
                    username = "${user}";
                    stateVersion = "20.09";
                  };
                }
              ];
              extraSpecialArgs = {
                inherit inputs;
              };
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

      # Nixpkgs packages with our overlays and packages.
      packages = pkgss;

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
            agenix.defaultPackage.${platform}
            deploy
            git
            git-crypt
            nix
            nopt
            update
            (writeShellScriptBin "deploy-home" ''
              nix run .#home-manager -- switch --flake ".#$(hostname)" "$@"
            '')
          ];

          # Enable flakes even though they are optional
          NIX_CONF_DIR = let
            current = pkgss.${platform}.lib.optionalString (builtins.pathExists /etc/nix/nix.conf)
              (builtins.readFile /etc/nix/nix.conf);

            nixConf = pkgss.${platform}.writeTextDir "opt/nix.conf" ''
              ${current}
              experimental-features = nix-command flakes
            '';
          in "${nixConf}/opt";
        }
      );
    };
}
