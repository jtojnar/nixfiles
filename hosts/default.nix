# Let’s build a configuration for each host listed in ./list.nix.
{ inputs, pkgss }:

let
  inherit (inputs)
    self
    agenix
    nixpkgs
    home-manager
    ;
  inherit (nixpkgs) lib;

  mkConfig =
    {
      hostName,
      platform,
      managedHome ? false,
      ...
    }:
    let
      pkgs = pkgss.${platform};
    in
    lib.nixosSystem {
      # Platform the host will be running on.
      system = platform;

      # Pass flake ‘inputs’ as an argument to all modules.
      specialArgs = {
        inherit inputs;
      };

      # Use our own lib, potentially with overlays.
      inherit (pkgs) lib;

      # Entry modules that will be imported to make the system.
      modules =
        let
          # Basic profile used by all the systems.
          core = self.nixosModules.profiles.core;

          # Some common configuration related to flakes/Nix so it cannot be placed anywhere else.
          global = {
            networking.hostName = hostName;

            # Nuke NIX_PATH.
            nix.nixPath = [ ];

            # For nixos-version.
            system.configurationRevision =
              self.rev or (
                if self ? "dirtyRev" then
                  "${self.dirtyRev}-${self.lastModifiedDate}"
                else
                  "dirty-${self.lastModifiedDate}"
              );

            nixpkgs = {
              inherit pkgs;
            };
          };

          # The host-specific configuration.
          local = ./${hostName}/configuration.nix;

          # Import every module listed in ‘/common/modules/list.nix’ so that we can use their options without importing them manually.
          # Though avoid importing profiles since those set config values.
          flakeModules = builtins.attrValues (builtins.removeAttrs self.nixosModules [ "profiles" ]);

          hmModules = lib.optionals managedHome [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        in
        flakeModules
        ++ [
          core
          global
          local
        ]
        ++ hmModules
        ++ [
          agenix.nixosModules.age
        ];
    };

  hosts = builtins.mapAttrs (
    hostName: props: mkConfig ({ inherit hostName; } // props)
  ) (import ./list.nix);
in
hosts
