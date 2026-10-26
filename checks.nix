# Everything `nix flake check` runs, on Linux and on a Mac alike.
#
# Each of this repository's modules is added, on its own, to an account on a
# bare machine of both classes, as core.nix's checks do for core's, so a
# module that quietly depends on another fails here rather than on a machine.
# Then come the personal layer on each class, the machines themselves and the
# promises they make. Evaluating builds nothing, so most checks take seconds;
# neovim-loads starts Neovim once. Last, every check's name is held to the
# glossary of the core this repository locks, as core's own names are.
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
    pi = [ self.homeModules.pi ];
  };

  unchecked = lib.subtractLists (lib.attrNames homeOnBoth) (
    lib.attrNames (builtins.readDir ./modules)
  );

  inherit (self.nixosConfigurations) penelope;
  inherit (self.darwinConfigurations) methuselah;
  git = machine: machine.config.home-manager.users.jitsusama.programs.git;

  # What only a Shopify machine reaches for: devx, the proxy and LLM gateway
  # it signs in to, and the tec toolchain it installs. A word is looked for
  # by replacing it rather than with lib.hasInfix, whose regular expression
  # overflows the stack on a file as long as some of these.
  namesShopify =
    text:
    lib.any (word: builtins.replaceStrings [ word ] [ "" ] text != text) [
      "devx"
      "shopify-proxy"
      "llm-gateway"
      "tec/toolchain"
    ];

  # Everything a machine and its account set that could name a program: the
  # environment, the paths, the files written, the packages, the shells'
  # startup, pi's settings and its Ask row, and the services.
  whatItSets =
    machine:
    let
      system = machine.config;
      home = system.home-manager.users.jitsusama;
      asJson = value: (builtins.tryEval (builtins.toJSON value)).value or "";
      written = files: lib.mapAttrsToList (target: file: target + toString (file.text or null)) files;
      named = packages: map lib.getName packages;
      # A service is read for what it runs and the environment it runs in,
      # not whole, since some of what modules derive from one fails to
      # evaluate for a service it doesn't suit.
      runs = pick: services: lib.mapAttrsToList (_: service: asJson (pick service)) services;
      systemdRuns = service: {
        script = service.script or "";
        path = service.path or [ ];
        environment = service.environment or { };
        exec = service.serviceConfig.ExecStart or null;
      };
      launchdRuns = service: {
        script = service.script or "";
        path = service.path or [ ];
        environment = service.environment or { };
        config = service.serviceConfig or service.config or { };
      };
    in
    [
      (asJson home.home.sessionVariables)
      (asJson home.home.sessionPath)
      (asJson home.home.shellAliases)
      (asJson home.jitsusama.pi.settings)
      (asJson home.jitsusama.pi.ask)
      (home.programs.zsh.envExtra or "")
      (home.programs.zsh.profileExtra or "")
      (home.programs.zsh.loginExtra or "")
      (home.programs.zsh.initContent or "")
      (home.programs.bash.profileExtra or "")
      (home.programs.bash.bashrcExtra or "")
      (home.programs.bash.initExtra or "")
      (asJson system.environment.variables)
      (system.environment.extraInit or "")
    ]
    ++ runs (service: service.config) (home.launchd.agents or { })
    ++ runs (service: service.Service or { }) (home.systemd.user.services or { })
    ++ runs launchdRuns (system.launchd.user.agents or { })
    ++ runs systemdRuns (system.systemd.services or { })
    ++ runs systemdRuns (system.systemd.user.services or { })
    ++ written home.home.file
    ++ written system.environment.etc
    ++ named home.home.packages
    ++ named system.environment.systemPackages;

  checks =
    checkEach "home-on-nixos" (modules: bareNixos [ (inAccount modules) ]) homeOnBoth
    // checkEach "home-on-darwin" (modules: bareDarwin [ (inAccount modules) ]) homeOnBoth
    // {
      inherit formatting;

      # Every doc names only what exists, as core's do: a link or a backticked
      # path from one of this repository's top folders that names nothing fails.
      docs-name-what-exists = core.lib.docsNameWhatExists pkgs {
        src = self;
        exempt = [ ];
      };

      # Every folder says what it holds, as core's do: in a README, the opening
      # comment of its entry file, a line of its parent's README opening with
      # its name, or for a top folder a line of the README's map.
      every-folder-says-what-it-holds = core.lib.everyFolderSaysWhatItHolds pkgs {
        src = self;
      };

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

      # Installed, penelope finishes itself with core's guide, which seals its
      # disk to the TPM.
      penelope-finishes-with-the-guide =
        holds "penelope-finishes-with-the-guide" "penelope has no guide to seal its disk to the TPM."
          (
            penelope.config.environment.etc ? "guide/machine.json"
            && lib.any (package: lib.getName package == "guide") penelope.config.environment.systemPackages
          );

      # penelope signs in as optimus does: Joel's account by itself after the
      # disk unlocks, and core's greeter in his look after a logout, rather
      # than tuigreet alone, which is what a machine naming no account gets.
      penelope-greets-in-joels-look =
        holds "penelope-greets-in-joels-look"
          "penelope's greeter is tuigreet alone, or Joel's account doesn't sign in by itself."
          (
            let
              inherit (penelope.config.services.greetd) settings;
            in
            (settings.initial_session.user or null) == "jitsusama"
            && !(lib.hasInfix "tuigreet" (lib.head (lib.splitString " " settings.default_session.command)))
          );

      # The machine of this system's Neovim starts with every plugin and the
      # personal layer's Lua without an error: core's index of the plugins is
      # written by starting it once and loading each, and fails on the first
      # error. The personal Lua once broke here by requiring a plugin core now
      # loads only when wanted. Each system starts its own machine's, so a Mac
      # checks methuselah's without a Linux builder.
      neovim-loads =
        let
          machine = if pkgs.stdenv.hostPlatform.isLinux then penelope else methuselah;
        in
        machine.config.home-manager.users.jitsusama.xdg.configFile."nvim/lua/waiting.lua".source;

      # Both machines leave pi's settings file pi's, declaring their own settings
      # through core's option: a link to the file in the store is replaced by
      # core's merge, and the next switch refuses to clobber what's there.
      pi-settings-stay-pis =
        holds "pi-settings-stay-pis"
          "A personal machine links pi's settings file, or doesn't declare its model through core."
          (
            lib.all
              (
                machine:
                let
                  home = machine.config.home-manager.users.jitsusama;
                in
                !(home.home.file ? ".pi/agent/settings.json")
                && home.jitsusama.pi.settings.defaultModel or null == "claude-sonnet-5"
              )
              [
                penelope
                methuselah
              ]
          );

      # Both machines have one pi, on Joel's own Claude plan through Claude
      # Code's login, with no pi-claude beside it and no other login named.
      one-pi-on-the-plan =
        holds "one-pi-on-the-plan"
          "A personal machine's pi isn't on the Claude plan, or keeps pi-claude or a login folder of its own."
          (
            lib.all
              (
                machine:
                let
                  home = machine.config.home-manager.users.jitsusama;
                in
                home.jitsusama.pi.plan == "claude"
                && home.jitsusama.pi.settings.defaultProvider or null == "claude-code"
                && !(lib.any (package: lib.getName package == "pi-claude") home.home.packages)
                && !(home.home.sessionVariables ? PI_CLAUDE_CONFIG_DIR)
              )
              [
                penelope
                methuselah
              ]
          );

      # Nothing on a personal machine needs devx or a Shopify sign-in: no
      # setting, file, package, path or service names devx, Shopify's proxy,
      # its LLM gateway or its tec toolchain. Generated files are read as
      # their settings write them, not as built, so this builds nothing.
      no-devx-for-personal-work =
        holds "no-devx-for-personal-work"
          "A personal machine's configuration names devx, shopify-proxy, the llm-gateway or the tec toolchain."
          (
            lib.all (machine: !(lib.any namesShopify (whatItSets machine))) [
              penelope
              methuselah
            ]
          );

      # Both machines' git reads the ignores home-manager writes, core's among
      # them, which an excludes file of their own would stop it reading, and
      # names no commit template, which git refuses a commit for when it's gone.
      git-reads-cores-ignores =
        holds "git-reads-cores-ignores"
          "A personal machine's git names its own excludes file or a commit template."
          (
            lib.all
              (
                machine:
                let
                  inherit ((git machine)) settings;
                in
                !(settings ? core.excludesFile) && !(settings ? commit.template)
              )
              [
                penelope
                methuselah
              ]
          );

      # Both machines commit as Joel outside work, and sign every commit, as
      # core's signing tells git in the include it writes last.
      one-personal-git =
        holds "one-personal-git" "A personal machine's git has another email or doesn't sign."
          (
            lib.all
              (
                machine:
                let
                  signing = lib.findFirst (include: include ? contents.gpg.format) { } (git machine).includes;
                in
                (git machine).settings.user.email == "joel@grrbrr.ca" && (signing.contents.commit.gpgSign or false)
              )
              [
                penelope
                methuselah
              ]
          );
    };
in
checks
// {
  # No check's name says a name core's glossary replaces, so this
  # repository's names are the words Joel reads everywhere else.
  no-name-says-a-replaced-word = core.lib.namesSayTheGlossary pkgs {
    names = lib.attrNames checks ++ [ "no-name-says-a-replaced-word" ];
  };
}
