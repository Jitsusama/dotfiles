# Joel's personal machines, built on core.nix. This is the index: it names
# every machine, the personal layer and the modules that take an input, and
# gives each file what it takes. To see how any file fits, find its path here.
{
  description = "Joel's personal machines, built on core.nix";

  inputs = {
    core.url = "github:Jitsusama/core.nix";
    # core.nix pins these, and every machine runs the combination its checks
    # passed with.
    nixpkgs.follows = "core/nixpkgs";
    nix-darwin.follows = "core/nix-darwin";
    treefmt-nix.follows = "core/treefmt-nix";
    # Joel's agent harness: pi's package of it, the CLI holding its logic,
    # and Claude Code's plugin of it. Each is read as files.
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
      treefmt-nix,
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
      treefmt = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

      # The module a file makes once it's given what it takes from here, as
      # core.nix makes its own. The key gives it the identity a path import
      # has, so importing it twice counts once and disabledModules can name it.
      moduleFrom = file: given: {
        key = toString file;
        imports = [ (nixpkgs.lib.modules.importApply file given) ];
      };
    in
    {
      homeModules = {
        personal = moduleFrom ./layers/personal/home.nix {
          inherit core;
          inherit (self) homeModules;
        };
        agentic-harness-core = moduleFrom ./modules/agentic-harness-core/home.nix {
          inherit agentic-harness-core;
        };
        claude = moduleFrom ./modules/claude/home.nix {
          inherit agentic-harness-pi agentic-harness-claude;
        };
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
          core.nixosModules.microsoft-surface-laptop-4-1958
          core.nixosModules.disko
          core.nixosModules.lanzaboote
          self.nixosModules.personal
          ./machines/penelope/nixos.nix
        ];
      };

      checks = forEachSystem (
        pkgs:
        import ./checks.nix {
          inherit
            self
            core
            pkgs
            nixpkgs
            nix-darwin
            ;
          formatting = (treefmt pkgs).config.build.check self;
        }
      );

      # `nix run .#guide` writes penelope's stick on any x86-64 Linux machine:
      # its whole install, sealed in the vault, for the guide on the stick to
      # install with no network. The Nano is enrolled first, since it's the
      # one almost always plugged in.
      packages.x86_64-linux.guide = core.lib.guide {
        inherit (self.nixosConfigurations.penelope) config;
        yubikeys = [
          "the Nano"
          "the 5Ci"
        ];
        account = "jitsusama";
      };

      formatter = forEachSystem (pkgs: (treefmt pkgs).config.build.wrapper);

      # The formatter on the path, for editors and for running it by hand.
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell { packages = [ (treefmt pkgs).config.build.wrapper ]; };
      });
    };
}
