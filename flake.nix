{
  description = "Flake w/Home Manager and Nix Darwin Support";

  inputs = {
    core.url = "github:Jitsusama/core.nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wallpapers.url = "github:Jitsusama/wallpapers.nix";
    agentic-harness-pi = {
      url = "github:Jitsusama/agentic-harness.pi";
      flake = false;
    };
    agentic-harness-core = {
      url = "github:Jitsusama/agentic-harness.core";
      flake = false;
    };
    agentic-harness-claude = {
      url = "github:Jitsusama/agentic-harness.claude";
      flake = false;
    };
  };

  outputs =
    {
      core,
      nixpkgs,
      home-manager,
      nix-darwin,
      wallpapers,
      agentic-harness-pi,
      agentic-harness-core,
      agentic-harness-claude,
      ...
    }:
    let
      darwinPkgs = import nixpkgs (import ./nixpkgs.nix { system = "aarch64-darwin"; });
      linuxPkgs = import nixpkgs (import ./nixpkgs.nix { system = "x86_64-linux"; });
    in
    {
      darwinConfigurations."methuselah" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = darwinPkgs;
        modules = [
          core.nix-darwin
          ./modules/nix-darwin
          ./hosts/methuselah/nix-darwin
        ];
        specialArgs = {
          username = "jitsusama";
        };
      };

      nixosConfigurations."penelope" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        pkgs = linuxPkgs;
        modules = [
          # TODO: Add core.nixos when available in core.nix
          ./modules/nixos
          ./hosts/penelope/nixos
        ];
        specialArgs = {
          username = "jitsusama";
        };
      };

      homeConfigurations = {
        "jitsusama@methuselah" = home-manager.lib.homeManagerConfiguration {
          pkgs = darwinPkgs;
          modules = [
            core.home-manager
            ./modules/home-manager
            ./hosts/methuselah/home-manager
          ];
          extraSpecialArgs = {
            inherit wallpapers agentic-harness-pi agentic-harness-core agentic-harness-claude;
            username = "jitsusama";
            homeDirectory = "/Users/jitsusama";
            neovim-pi = core.neovim-pi;
          };
        };

        "jitsusama@penelope" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          modules = [
            core.home-manager
            ./modules/home-manager
            ./hosts/penelope/home-manager
          ];
          extraSpecialArgs = {
            inherit wallpapers agentic-harness-pi agentic-harness-core agentic-harness-claude;
            username = "jitsusama";
            homeDirectory = "/home/jitsusama";
            neovim-pi = core.neovim-pi;
          };
        };
      };

      devShells = {
        "aarch64-darwin".default = darwinPkgs.mkShell {
          buildInputs = [
            home-manager.packages."aarch64-darwin".home-manager
            nix-darwin.packages."aarch64-darwin".darwin-rebuild
          ];
        };

        "x86_64-linux".default = linuxPkgs.mkShell {
          buildInputs = [
            home-manager.packages."x86_64-linux".home-manager
          ];
        };
      };
    };
}
