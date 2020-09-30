{
  description = "jtojnar’s machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixgl = {
      url = "github:guibou/nixGL";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixgl }@inputs:
    let
      inherit (nixpkgs) lib;

      # Flakes require ‘packages’ attribute to contain per-platform attrsets.
      # Here we explicitly define all the platforms that will be exposed.
      platforms = [
        "x86_64-linux"
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
        overlays = builtins.attrValues self.overlays;
        config = { allowUnfree = true; };
      };

      # Package sets for each platform.
      pkgss = forAllPlatforms mkPkgs;
    in {
      # Configurations for our hosts.
      # These are used by tools like nixos-rebuild.
      nixosConfigurations =
        let
          configs = import ./hosts { inherit inputs pkgss; };
        in configs;

      # Overlay containing our packages defined in this repository.
      overlay = import ./common/pkgs;

      # All our overlays.
      # We will apply them to all hosts.
      overlays =
        let
          overlayDir = ./common/overlays;
          fullPath = name: overlayDir + "/${name}";
          overlayPaths = map fullPath (builtins.attrNames (builtins.readDir overlayDir));
        in pathsToImportedAttrs overlayPaths;

      # All our packages listed in /common/pkgs.
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
            nixFlakes
            update
            (writeShellScriptBin "deploy-nix-profile" ''
              profile="hosts/$(hostname)/profile.nix"
              if [[ ! -f $profile ]]; then
                  echo "Missing profile.nix for host “$(hostname)”"
                  exit 1
              fi

              nix-env -f "$profile" --remove-all --install
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
