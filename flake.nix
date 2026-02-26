{
  description = "Yuta-PC NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-unified.url = "github:srid/nixos-unified";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ inputs.nixos-unified.flakeModules.default ];

      flake = let
        myUserName = "yuta";
      in {
        nixosConfigurations."Yuta-PC" =
          self.nixos-unified.lib.mkLinuxSystem
            { home-manager = true; }
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              nixpkgs.config.allowUnfree = true;
              nixpkgs.overlays = [
                (final: _prev: {
                  unstable = import inputs.nixpkgs-unstable {
                    system = final.system;
                    config.allowUnfree = true;
                  };
                })
              ];
              imports = [
                ./nixos
                {
                  home-manager.users.${myUserName} = {
                    imports = [ self.homeModules.default ];
                  };
                }
              ];
            };

        homeModules.default = import ./home;
      };
    };
}
