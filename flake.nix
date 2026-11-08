# Joel's personal machines, built on core.nix. This is the index: it names
# every machine, the personal modules and the tools' modules that take an input, and
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
    # Joel's agent harness, pi's package of it, read as files. pi itself
    # loads the copy pi-packages keeps current, which core.nix names, so this
    # pin is only what Claude Code's skills are built from (modules/claude),
    # and updating it moves pi nowhere.
    agentic-harness-pi = {
      url = "github:Jitsusama/agentic-harness.pi";
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
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      # The linters core holds itself to, and what only this repository has.
      treefmt =
        pkgs:
        treefmt-nix.lib.evalModule pkgs {
          imports = [
            core.treefmtModules.treefmt
            ./treefmt.nix
          ];
        };

      # The module a file makes once it's given what it takes from here, as
      # core.nix makes its own. The key gives it the identity a path import
      # has, so importing it twice counts once and disabledModules can name it.
      moduleFrom = file: given: {
        key = toString file;
        imports = [ (nixpkgs.lib.modules.importApply file given) ];
      };

      # The YubiKeys that open each machine's stick and disk. Each key's age
      # recipient, which age-plugin-fido2-hmac made for it, lets that key
      # open the vault; they are public halves.
      yubikeys = [
        {
          name = "the Nano";
          recipient = "age1fido2-hmac1qqpft42hf3garzhh4rfe522mlqfs7jrgdtza0pw78y0jvmssznxqxlgp4f25ln9fep0a4p9s27ly90tkwqyjv7jvznnl8ekm4pvzyvfytxmauuuqfs9hr0kxy294ewuamfpr8xjnvmxujgr096srshrkk2n03fqt7e058huhuh36ah0khr26x79a535v0xwtqzkhynkwm0phdlghuqlmkwhs";
        }
        {
          name = "the 5Ci";
          recipient = "age1fido2-hmac1qqp8s9hcznqx90l0tvjkuagna43sn3fe2nwq9fdwjvlsc9l7fkrm2pgpkuhnjmknjsdkvemqs8fh0unp7g7ye0mhl2c56xqm49a4g3d5f8y9ues92htqju8q2zjxuq38ejflr9hcqkxhpyd457fc5mr2t3r763574kf0r7tjv8r54lpgw7e2q4p62x4d6s08zzsj73z78j5rzjskqgj8vwz5";
        }
      ];

      # What each machine's guide is given, wherever its stick is written
      # from.
      penelopeGuide = {
        inherit (self.nixosConfigurations.penelope) config;
        inherit yubikeys;
        account = "jitsusama";
      };
      methuselahGuide = {
        inherit (self.nixosConfigurations.methuselah) config;
        inherit yubikeys;
        account = "jitsusama";
      };
    in
    {
      homeModules = {
        personal = moduleFrom ./personal/home.nix {
          inherit core;
          inherit (self) homeModules;
        };
        claude = moduleFrom ./modules/claude/home.nix { inherit agentic-harness-pi; };
        neovim = moduleFrom ./modules/neovim/home.nix { inherit core; };
        pi = moduleFrom ./modules/pi/home.nix { inherit core; };
      };
      darwinModules.personal = moduleFrom ./personal/darwin.nix { inherit (self) homeModules; };
      nixosModules.personal = moduleFrom ./personal/nixos.nix { inherit (self) homeModules; };

      darwinConfigurations.methuselah = nix-darwin.lib.darwinSystem {
        modules = [
          core.darwinModules.workstation
          core.darwinModules.graphical
          core.darwinModules.linux-builder
          core.darwinModules.update-to-main
          self.darwinModules.personal
          ./machines/methuselah/darwin.nix
        ];
      };

      # methuselah as it will run once it's wiped onto NixOS, built and checked
      # beside the Mac it is today.
      nixosConfigurations.methuselah = nixpkgs.lib.nixosSystem {
        modules = [
          core.nixosModules.workstation
          core.nixosModules.graphical
          core.nixosModules.laptop
          core.nixosModules.apple-macbook-air-m2-a2681
          core.nixosModules.disko
          core.nixosModules.guide
          core.nixosModules.update-to-main
          self.nixosModules.personal
          ./machines/methuselah/nixos.nix
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
          core.nixosModules.guide
          core.nixosModules.update-to-main
          self.nixosModules.personal
          ./machines/penelope/nixos.nix
          # While the freeze of 2026-10-26 is chased; freeze-capture.nix says why.
          core.nixosModules.disk-loss-panic
          ./machines/penelope/freeze-capture.nix
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

      # `nix run .#guide` writes penelope's stick on any x86-64 Linux machine
      # or a Mac: its whole install, sealed in the vault, for the guide on the
      # stick to install with no network. The Nano is enrolled first, since
      # it's the one almost always plugged in.
      packages.x86_64-linux.guide = core.lib.guide penelopeGuide;
      # The stick a Mac writes is the same x86-64 Linux one, which it takes
      # from a cache or an x86-64 Linux builder.
      packages.aarch64-darwin.guide = core.lib.guide (penelopeGuide // { host = "aarch64-darwin"; });
      # `nix run .#methuselah-guide` writes methuselah's stick the same way:
      # aarch64 Linux on Asahi's kernel, from optimus or from the Mac itself,
      # either taking it from an aarch64 Linux builder.
      packages.x86_64-linux.methuselah-guide = core.lib.guide methuselahGuide;
      packages.aarch64-darwin.methuselah-guide = core.lib.guide (
        methuselahGuide // { host = "aarch64-darwin"; }
      );

      formatter = forEachSystem (pkgs: (treefmt pkgs).config.build.wrapper);

      # The formatter on the path, for editors and for running it by hand.
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell { packages = [ (treefmt pkgs).config.build.wrapper ]; };
      });
    };
}
