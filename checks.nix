# Everything `nix flake check` runs, on Linux and on a Mac alike.
#
# Each of this repository's modules is added, on its own, to an account on a
# bare machine of both classes, as core.nix's checks do for core's, so a
# module that quietly depends on another fails here rather than on a machine.
# Then come the personal layer on each class, the machines themselves and the
# promises they make. Evaluating builds nothing, so most checks take seconds;
# neovim-loads starts Neovim once.
{
  self,
  core,
  pkgs,
  nixpkgs,
  nix-darwin,
  formatting,
}:
let
  inherit (pkgs) lib;

  # The least a machine needs to evaluate, with core's home-manager and
  # nixpkgs settings, which every machine has, and one account for
  # home-manager to configure.
  bareNixos =
    modules:
    nixpkgs.lib.nixosSystem {
      modules = [
        core.nixosModules.home-manager
        core.nixosModules.nixpkgs
        {
          nixpkgs.hostPlatform = "x86_64-linux";
          boot.loader.grub.enable = false;
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
          users.users.someone.isNormalUser = true;
          home-manager.users.someone.home.stateVersion = "26.05";
          system.stateVersion = "26.05";
        }
      ]
      ++ modules;
    };

  bareDarwin =
    modules:
    nix-darwin.lib.darwinSystem {
      modules = [
        core.darwinModules.home-manager
        core.darwinModules.nixpkgs
        {
          nixpkgs.hostPlatform = "aarch64-darwin";
          system.primaryUser = "someone";
          users.users.someone.home = "/Users/someone";
          home-manager.users.someone.home.stateVersion = "26.05";
          system.stateVersion = 6;
        }
      ]
      ++ modules;
    };

  # Home-manager modules, given to the bare machine's one account.
  inAccount = modules: { home-manager.users.someone.imports = modules; };

  # A check that passes when the machine evaluates. Writing out the path of
  # its derivation forces the whole configuration while building none of it.
  evaluates =
    name: machine:
    pkgs.writeText name (
      builtins.unsafeDiscardStringContext machine.config.system.build.toplevel.drvPath
    );

  # A check that passes when a condition about the machines holds.
  holds =
    name: message: condition:
    if condition then
      pkgs.writeText name ""
    else
      pkgs.runCommandLocal name { } ''
        echo ${lib.escapeShellArg message}
        exit 1
      '';

  # One check per module, named after where it was added: "home-on-darwin-pi"
  # is the pi module in an account on a bare Mac.
  checkEach =
    where: addToBareMachine: modules:
    lib.mapAttrs' (name: module: {
      name = "${where}-${name}";
      value = evaluates "${where}-${name}" (addToBareMachine module);
    }) modules;

  # Every module in modules/, with whatever the account has to give it. Each
  # runs on both classes of machine.
  homeOnBoth = {
    agentic-harness-core = [ self.homeModules.agentic-harness-core ];
    claude = [ self.homeModules.claude ];
    neovim = [ ./modules/neovim/home.nix ];
    pi = [ ./modules/pi/home.nix ];
  };

  unchecked = lib.subtractLists (lib.attrNames homeOnBoth) (
    lib.attrNames (builtins.readDir ./modules)
  );

  inherit (self.nixosConfigurations) penelope;
  inherit (self.darwinConfigurations) methuselah;
  git = machine: machine.config.home-manager.users.jitsusama.programs.git;
in
checkEach "home-on-nixos" (modules: bareNixos [ (inAccount modules) ]) homeOnBoth
// checkEach "home-on-darwin" (modules: bareDarwin [ (inAccount modules) ]) homeOnBoth
// {
  inherit formatting;

  every-module-is-checked =
    holds "every-module-is-checked"
      "checks.nix doesn't add these modules to a bare machine: ${lib.concatStringsSep ", " unchecked}"
      (unchecked == [ ]);

  # The personal layer on each class of machine, as the machines use it.
  nixos-personal = evaluates "nixos-personal" (bareNixos [ self.nixosModules.personal ]);
  darwin-personal = evaluates "darwin-personal" (bareDarwin [ self.darwinModules.personal ]);

  penelope = evaluates "penelope" penelope;
  methuselah = evaluates "methuselah" methuselah;

  # penelope installs onto core's encrypted disk on its own NVMe drive, and
  # boots through lanzaboote with Secure Boot keys of its own, so the guide
  # that installs it and the firmware that enforces its keys agree.
  penelope-boots-under-its-own-keys =
    let
      inherit (penelope.config) boot jitsusama;
    in
    holds "penelope-boots-under-its-own-keys"
      "penelope doesn't install onto core's disk on its NVMe drive, or doesn't boot through lanzaboote with its own keys."
      (
        boot.lanzaboote.enable
        && !boot.loader.systemd-boot.enable
        && boot.lanzaboote.pkiBundle == "/var/lib/sbctl"
        && lib.hasPrefix "/dev/disk/by-id/nvme-" jitsusama.disk.device
        && boot.initrd.luks.devices ? ${jitsusama.disk.name}
      );

  # penelope's Neovim starts with every plugin and the personal layer's Lua
  # without an error: core's index of the plugins is written by starting it
  # once and loading each, and fails on the first error. The personal Lua
  # once broke here by requiring a plugin core now loads only when wanted.
  neovim-loads =
    penelope.config.home-manager.users.jitsusama.xdg.configFile."nvim/lua/waiting.lua".source;

  # Both machines commit as Joel outside work, and sign every commit.
  one-personal-git =
    holds "one-personal-git" "A personal machine's git has another email or doesn't sign."
      (
        lib.all
          (
            machine:
            (git machine).settings.user.email == "joel@grrbrr.ca" && (git machine).signing.signByDefault
          )
          [
            penelope
            methuselah
          ]
      );
}
