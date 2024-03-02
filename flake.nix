{
  description = "jtojnar’s machines";

  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      # HACK: Prevent adding a nix-darwin copy.
      inputs.darwin.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    napalm = {
      url = "github:nix-community/napalm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = github:the-argus/spicetify-nix;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, agenix, c4, dwarffs, flake-compat, home-manager, napalm, nixpkgs, spicetify-nix }@inputs:
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
          name = lib.removeSuffix ".nix" (builtins.baseNameOf (lib.removeSuffix "/default.nix" (builtins.toString path)));
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
            (locallyOverrideFinal (final: { nix = final.nixVersions.nix_2_19; }))
            (filterOverlayAttrs [ "dwarffs" ])
          ])

          # Take only napalm attribute from napalm overlay and
          # pass it the latest nodejs.
          (lib.pipe napalm.overlays.default [
            (locallyOverrideFinal (final: { nodejs = final.nodejs; }))
            (filterOverlayAttrs [ "napalm" ])
          ])

          (final: prev: {
            home-manager = prev.callPackage "${home-manager}/home-manager" { };

            spicePkgs = spicetify-nix.packages.${platform}.default;

            python3 = prev.python3.override ({
              packageOverrides = psuper: pprev: {
                inkex = pprev.inkex.overrideAttrs (attrs: {
                  postPatch = attrs.postPatch + ''
                    # Loosen lxml bounds.
                    # https://github.com/NixOS/nixpkgs/pull/292770
                    substituteInPlace pyproject.toml \
                      --replace-fail 'lxml = "^4.5.0"' 'lxml = "^4.5.0 || ^5.0.0"'
                  '';
                });
              };
            });
          })
        ];
        config = {
          allowUnfree = true;
          allowAliases = false;
          permittedInsecurePackages = [
            # Will not be available for the whole lifetime of NixOS 23.05.
            "openssl-1.1.1w"
          ];
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

      # All our overlays.
      # The packages defined in this repository are defined in ‘./pkgs’ and linked to the ‘default’ overlay.
      # We will apply them to all hosts.
      overlays =
        let
          overlayDir = ./common/overlays;
          fullPath = name: overlayDir + "/${name}";
          overlayPaths = map fullPath (builtins.attrNames (builtins.readDir overlayDir));
        in pathsToImportedAttrs overlayPaths;

      # Nixpkgs packages with our overlays and packages.
      legacyPackages = pkgss;

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

      # All our home-manager modules and profiles that can be imported.
      # A profile in /common/home-profiles/foo.nix can be accessed as ‘${flakeRef}.homeModules.profiles.foo’
      # The key name from https://github.com/nix-community/home-manager/issues/1783#issuecomment-1461178166
      homeModules =
        let
          modulesAttrs = { };

          profilesAttrs = {
            profiles = pathsToImportedAttrs (import ./common/home-profiles/list.nix);
          };
        in modulesAttrs // profilesAttrs;

      # Development shell containing our maintenance utils
      devShells = forAllPlatforms (platform: {
        default = pkgss.${platform}.mkShell {
          nativeBuildInputs = with pkgss.${platform}; [
            agenix.packages.${platform}.default
            deploy
            git
            git-crypt
            nix
            nopt
            update
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
        };
      });
    };
}
