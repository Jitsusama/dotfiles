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
  };

  outputs =
    {
      core,
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      username = "jitsusama";
      homeDirectory = "/Users/${username}";

      system = "aarch64-darwin";
      pkgs = import nixpkgs (
        import ./nixpkgs.nix {
          inherit system;
        }
      );
    in
    {
      darwinConfigurations."methuselah" = nix-darwin.lib.darwinSystem {
        inherit system pkgs;
        modules = [
          core.nix-darwin
          ./modules/nix-darwin
          ./hosts/methuselah/nix-darwin
        ];
        specialArgs = { inherit username; };
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          core.home-manager
          ./modules/home-manager
          ./hosts/methuselah/home-manager
        ];
        extraSpecialArgs = { inherit username homeDirectory; };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          home-manager.packages.${system}.home-manager
          nix-darwin.packages.${system}.darwin-rebuild
        ];
        shellHook = ''
          echo "Commands:"
          echo "  sudo darwin-rebuild switch --flake ."
          echo "  home-manager switch --flake ."
          echo "  home-manager news --flake ."
          echo "  nix flake update"
        '';
      };
    };
}
