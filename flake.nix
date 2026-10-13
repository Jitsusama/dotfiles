{
  description = "Joel's personal machines, built on core.nix";

  inputs = {
    core.url = "github:Jitsusama/core.nix";
    nixpkgs.follows = "core/nixpkgs";
    nix-darwin.follows = "core/nix-darwin";
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
      self,
      core,
      nixpkgs,
      nix-darwin,
      agentic-harness-pi,
      agentic-harness-core,
      agentic-harness-claude,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # A module file that takes this flake's inputs as an outer function, as
      # core.nix's own do.
      moduleFrom = file: given: {
        key = toString file;
        imports = [ (nixpkgs.lib.modules.importApply file given) ];
      };
    in
    {
      homeModules.personal = moduleFrom ./layers/personal/home.nix {
        inherit
          core
          agentic-harness-pi
          agentic-harness-core
          agentic-harness-claude
          ;
      };
      darwinModules.personal = moduleFrom ./layers/personal/darwin.nix { inherit (self) homeModules; };
      nixosModules.personal = moduleFrom ./layers/personal/nixos.nix { inherit (self) homeModules; };

      darwinConfigurations.methuselah = nix-darwin.lib.darwinSystem {
        modules = [
          core.darwinModules.workstation
          core.darwinModules.graphical
          self.darwinModules.personal
          ./machines/methuselah/darwin.nix
        ];
      };

      nixosConfigurations.penelope = nixpkgs.lib.nixosSystem {
        modules = [
          core.nixosModules.workstation
          core.nixosModules.graphical
          core.nixosModules.laptop
          self.nixosModules.personal
          ./machines/penelope/nixos.nix
        ];
      };

      formatter = forEachSystem (pkgs: pkgs.nixfmt-tree);

      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell { packages = [ pkgs.nixfmt-tree ]; };
      });
    };
}
