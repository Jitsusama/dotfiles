{
  description = "Flake w/Home Manager and Nix Darwin Support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin }:
    let
      system = "aarch64-darwin";
      nixpkgsConfig = import ./nixpkgs.nix { inherit system; };
      pkgs = nixpkgs.legacyPackages.${system};
      username = "jitsusama";
      homeDirectory = "/Users/${username}";
    in
    {
      # Home Manager Configuration
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ 
          { 
            nixpkgs.config = nixpkgsConfig.config;
            nixpkgs.overlays = nixpkgsConfig.overlays;
          }
          ./home.nix 
        ];
        extraSpecialArgs = { inherit username homeDirectory; };
      };

      # macOS System Configuration
      darwinConfigurations.default = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [ 
          { nixpkgs = nixpkgsConfig; }
          ./darwin.nix 
        ];
        specialArgs = { inherit username; };
      };

      # Development Shell For Managing This Configuration
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          home-manager.packages.${system}.home-manager
        ];
        shellHook = ''
          echo "Nix configuration management shell"
          echo "Commands:"
          echo "  home-manager switch --flake ."
          echo "  sudo darwin-rebuild switch --flake ."
        '';
      };
    };
}

