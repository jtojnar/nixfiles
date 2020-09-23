# Let’s build a configuration for each host listed in ./list.nix.
{ inputs, pkgss }:
let
  inherit (inputs) self nixpkgs hm;
  inherit (nixpkgs) lib;

  mkConfig = { hostName, platform, ... }:
    lib.nixosSystem {
      # Platform the host will be running on.
      system = platform;

      # Pass flake ‘inputs’ as an argument to all modules.
      specialArgs = {
        inherit inputs;
      };

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
            system.configurationRevision = self.rev or "dirty-${self.lastModifiedDate}";

            nixpkgs = {
              pkgs = pkgss.${platform};
            };
          };

          # The host-specific configuration.
          local = import "${toString ./.}/${hostName}/configuration.nix";

          # Import every module listed in ‘/common/modules/list.nix’ so that we can use their options without importing them manually.
          # Though avoid importing profiles since those set config values.
          flakeModules =
            builtins.attrValues (builtins.removeAttrs self.nixosModules [ "profiles" ]);
        in
          flakeModules ++ [ core global local ];
    };

  mkHomeConfig = { hostName, platform, username, ... }:
    hm.lib.homeManagerConfiguration {
      configuration = "${./.}/${hostName}/home.nix";
      system = platform;
      homeDirectory = "/home/${username}";
      inherit username;
      pkgs = pkgss.${platform};
    };

  hosts = import ./list.nix;

  createConfigs = maker:
    builtins.mapAttrs
      (hostName: props: maker ({ inherit hostName; } // props));
in
  {
    hm = createConfigs mkHomeConfig hosts.hm;
    nixos = createConfigs mkConfig hosts.nixos;
  }
