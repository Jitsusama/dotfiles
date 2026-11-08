# Everything `nix flake check` runs, on Linux and on a Mac alike.
#
# Each of this repository's modules is added, on its own, to an account on a
# bare machine of both classes, as core.nix's checks do for core's, so a
# module that quietly depends on another fails here rather than on a machine.
# Then come the personal modules on each class, the machines themselves and the
# promises they make, each condition of a promise failing with a line of its
# own that names the machine. Evaluating builds nothing, so most checks take
# seconds; what only fails when it runs is built for the machine of the
# system checking it: Neovim is started once, and Claude Code's skills and
# pi's package are built. Last, every check's name is held to the glossary of
# the core this repository locks, as core's own names are.
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

  # The bare machines, evaluates and holds are what core.nix's own checks
  # use, written again here because core doesn't export them.

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

  # A check that passes when every condition about the machines holds. Each
  # condition is given with what broke when it doesn't, and a failure prints
  # every one that broke, a line each, so it says which.
  holds =
    name: conditions:
    let
      broken = map (condition: condition.broke) (lib.filter (condition: !condition.holds) conditions);
    in
    if broken == [ ] then
      pkgs.writeText name ""
    else
      pkgs.runCommandLocal name { } ''
        printf '%s\n' ${lib.escapeShellArgs broken}
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
    claude = [ self.homeModules.claude ];
    neovim = [ self.homeModules.neovim ];
    pi = [ self.homeModules.pi ];
  };

  unchecked = lib.subtractLists (lib.attrNames homeOnBoth) (
    lib.attrNames (builtins.readDir ./modules)
  );

  inherit (self.nixosConfigurations) penelope;
  inherit (self.darwinConfigurations) methuselah;
  methuselahOnNixos = self.nixosConfigurations.methuselah;
  machines = { inherit penelope methuselah; };
  homeOf = machine: machine.config.home-manager.users.jitsusama;
  git = machine: (homeOf machine).programs.git;

  # The conditions a promise makes of each machine, given its name and the
  # machine, so each says which machine broke it.
  onEachMachine = conditions: lib.concatLists (lib.mapAttrsToList conditions machines);

  # The machine of the system checking, whose builds this system can make, so
  # a Mac checks methuselah's without a Linux builder.
  machineHere = if pkgs.stdenv.hostPlatform.isLinux then penelope else methuselah;

  # What only a Shopify machine reaches for: devx, the proxy and LLM gateway
  # it signs in to, and the tec toolchain it installs. A word is looked for
  # by replacing it rather than with lib.hasInfix, whose regular expression
  # overflows the stack on a file as long as some of these.
  shopifyWords = [
    "devx"
    "shopify-proxy"
    "llm-gateway"
    "tec/toolchain"
  ];
  says = word: text: builtins.replaceStrings [ word ] [ "" ] text != text;

  # Everything a machine and its account set that could name a program, each
  # with the option it's set in: the environment, the paths, the files
  # written, the packages, the shells' startup, pi's settings and its Ask row,
  # and the services.
  whatItSets =
    machine:
    let
      system = machine.config;
      home = homeOf machine;
      asJson = value: (builtins.tryEval (builtins.toJSON value)).value or "";
      set = where: text: { inherit where text; };
      ofAccount = where: text: set "home-manager's ${where}" text;
      written =
        option: files:
        lib.mapAttrsToList (target: file: set "${option}.${target}" (target + toString (file.text or null))) files;
      named =
        option: packages:
        map (package: set "${option} ${lib.getName package}" (lib.getName package)) packages;
      # A service is read for what it runs and the environment it runs in,
      # not whole, since some of what modules derive from one fails to
      # evaluate for a service it doesn't suit.
      runs =
        option: pick: services:
        lib.mapAttrsToList (name: service: set "${option}.${name}" (asJson (pick service))) services;
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
      (ofAccount "home.sessionVariables" (asJson home.home.sessionVariables))
      (ofAccount "home.sessionPath" (asJson home.home.sessionPath))
      (ofAccount "home.shellAliases" (asJson home.home.shellAliases))
      (ofAccount "jitsusama.pi.settings" (asJson home.jitsusama.pi.settings))
      (ofAccount "jitsusama.pi.ask" (asJson home.jitsusama.pi.ask))
      (ofAccount "programs.zsh.envExtra" (home.programs.zsh.envExtra or ""))
      (ofAccount "programs.zsh.profileExtra" (home.programs.zsh.profileExtra or ""))
      (ofAccount "programs.zsh.loginExtra" (home.programs.zsh.loginExtra or ""))
      (ofAccount "programs.zsh.initContent" (home.programs.zsh.initContent or ""))
      (ofAccount "programs.bash.profileExtra" (home.programs.bash.profileExtra or ""))
      (ofAccount "programs.bash.bashrcExtra" (home.programs.bash.bashrcExtra or ""))
      (ofAccount "programs.bash.initExtra" (home.programs.bash.initExtra or ""))
      (set "environment.variables" (asJson system.environment.variables))
      (set "environment.extraInit" (system.environment.extraInit or ""))
    ]
    ++ runs "home-manager's launchd.agents" (service: service.config) (home.launchd.agents or { })
    ++ runs "home-manager's systemd.user.services" (service: service.Service or { }) (
      home.systemd.user.services or { }
    )
    ++ runs "launchd.user.agents" launchdRuns (system.launchd.user.agents or { })
    ++ runs "systemd.services" systemdRuns (system.systemd.services or { })
    ++ runs "systemd.user.services" systemdRuns (system.systemd.user.services or { })
    ++ written "home-manager's home.file" home.home.file
    ++ written "environment.etc" system.environment.etc
    ++ named "home-manager's home.packages" home.home.packages
    ++ named "environment.systemPackages" system.environment.systemPackages;

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

      every-module-is-checked = holds "every-module-is-checked" [
        {
          holds = unchecked == [ ];
          broke = "checks.nix doesn't add these modules to a bare machine: ${lib.concatStringsSep ", " unchecked}";
        }
      ];

      # The personal modules on each class of machine, as the machines use them.
      nixos-personal = evaluates "nixos-personal" (bareNixos [ self.nixosModules.personal ]);
      darwin-personal = evaluates "darwin-personal" (bareDarwin [ self.darwinModules.personal ]);

      penelope = evaluates "penelope" penelope;
      methuselah = evaluates "methuselah" methuselah;
      # methuselah as NixOS on its M2, evaluated from any system before the
      # Mac is wiped onto it.
      methuselah-on-nixos = evaluates "methuselah-on-nixos" methuselahOnNixos;

      # penelope installs onto its own NVMe disk, encrypted as core lays it out, and
      # boots through lanzaboote with Secure Boot keys of its own, so the guide
      # that installs it and the firmware that enforces its keys agree.
      penelope-boots-under-its-own-keys =
        let
          inherit (penelope.config) boot jitsusama;
        in
        holds "penelope-boots-under-its-own-keys" [
          {
            holds = boot.lanzaboote.enable;
            broke = "penelope doesn't boot through lanzaboote.";
          }
          {
            holds = !boot.loader.systemd-boot.enable;
            broke = "penelope turns systemd-boot on, which lanzaboote replaces.";
          }
          {
            holds = boot.lanzaboote.pkiBundle == "/var/lib/sbctl";
            broke = "penelope's Secure Boot keys aren't its own, in /var/lib/sbctl.";
          }
          {
            holds = lib.hasPrefix "/dev/disk/by-id/nvme-" jitsusama.disk.device;
            broke = "penelope doesn't install onto its NVMe disk.";
          }
          {
            holds = boot.initrd.luks.devices ? ${jitsusama.disk.name};
            broke = "penelope's disk isn't encrypted as core lays it out.";
          }
        ];

      # Installed, penelope finishes itself with core's guide, which seals its
      # disk to the TPM.
      penelope-finishes-with-the-guide = holds "penelope-finishes-with-the-guide" [
        {
          holds = penelope.config.environment.etc ? "guide/machine.json";
          broke = "penelope has no guide/machine.json for the guide to finish it from.";
        }
        {
          holds = lib.any (package: lib.getName package == "guide") penelope.config.environment.systemPackages;
          broke = "penelope has no guide to seal its disk to the TPM.";
        }
      ];

      # penelope signs in as optimus does: Joel's account by itself after the
      # disk unlocks, and core's greeter in his look after a logout, rather
      # than tuigreet alone, which is what a machine naming no account gets.
      penelope-greets-in-joels-look =
        let
          inherit (penelope.config.services.greetd) settings;
        in
        holds "penelope-greets-in-joels-look" [
          {
            holds = (settings.initial_session.user or null) == "jitsusama";
            broke = "Joel's account doesn't sign in by itself on penelope.";
          }
          {
            holds = !(lib.hasInfix "tuigreet" (lib.head (lib.splitString " " settings.default_session.command)));
            broke = "penelope's greeter is tuigreet alone.";
          }
        ];

      # The machine of this system's Neovim starts with every plugin and the
      # personal modules' Lua without an error: core's index of the plugins is
      # written by starting it once and loading each, and fails on the first
      # error. The personal Lua once broke here by requiring a plugin core now
      # loads only when wanted.
      neovim-loads = (homeOf machineHere).xdg.configFile."nvim/lua/waiting.lua".source;

      # Claude Code's skills as the machine of this system installs them: the
      # patches apply with no fuzz, so one upstream has moved past fails here.
      claude-skills-build = (homeOf machineHere).home.file.".claude/skills/agentic-harness-pi".source;

      # pi as the machine of this system installs it, built from its npm
      # tarball and the lock file beside its package.
      pi-builds =
        lib.findFirst (package: lib.getName package == "pi-coding-agent")
          (throw "The machine of this system installs no pi-coding-agent package.")
          (homeOf machineHere).home.packages;

      # Both machines leave pi's settings file pi's, declaring their own settings
      # through core's option: a link to the file in the store is replaced by
      # core's merge, and the next switch refuses to clobber what's there.
      pi-settings-stay-pis = holds "pi-settings-stay-pis" (
        onEachMachine (
          name: machine:
          let
            home = homeOf machine;
          in
          [
            {
              holds = !(home.home.file ? ".pi/agent/settings.json");
              broke = "${name} links pi's settings file.";
            }
            {
              holds = home.jitsusama.pi.settings.defaultModel or null == "claude-sonnet-5";
              broke = "${name} doesn't declare pi's model, claude-sonnet-5, through core.";
            }
          ]
        )
      );

      # Both machines' pi names each package once, so the harness loads from
      # the version pi-packages swaps in and not a second time from git.
      pi-loads-each-package-once = holds "pi-loads-each-package-once" (
        onEachMachine (
          name: machine:
          let
            inherit ((homeOf machine).jitsusama.pi.settings) packages;
          in
          [
            {
              holds = lib.allUnique packages;
              broke = "${name}'s pi names a package twice.";
            }
            {
              holds = !(lib.any (lib.hasPrefix "git:") packages);
              broke = "${name}'s pi loads a package from git.";
            }
            {
              holds =
                packages != [ ]
                && lib.hasSuffix "/github.com/Jitsusama/agentic-harness.pi/current" (lib.head packages);
              broke = "${name}'s pi doesn't load the harness first, from pi-packages.";
            }
          ]
        )
      );

      # Both machines have one pi, on Joel's own Claude plan through Claude
      # Code's login, with no pi-claude beside it and no other login named.
      one-pi-on-the-plan = holds "one-pi-on-the-plan" (
        onEachMachine (
          name: machine:
          let
            home = homeOf machine;
          in
          [
            {
              holds = home.jitsusama.pi.plan == "claude";
              broke = "${name}'s pi isn't on the Claude plan.";
            }
            {
              holds = home.jitsusama.pi.settings.defaultProvider or null == "claude-code";
              broke = "${name}'s pi doesn't sign in through Claude Code.";
            }
            {
              holds = !(lib.any (package: lib.getName package == "pi-claude") home.home.packages);
              broke = "${name} keeps pi-claude.";
            }
            {
              holds = !(home.home.sessionVariables ? PI_CLAUDE_CONFIG_DIR);
              broke = "${name}'s pi keeps a login folder of its own, PI_CLAUDE_CONFIG_DIR.";
            }
          ]
        )
      );

      # Nothing on a personal machine needs devx or a Shopify sign-in: no
      # setting, file, package, path or service names devx, Shopify's proxy,
      # its LLM gateway or its tec toolchain. Generated files are read as
      # their settings write them, not as built, so this builds nothing.
      no-devx-for-personal-work = holds "no-devx-for-personal-work" (
        onEachMachine (
          name: machine:
          let
            sets = whatItSets machine;
          in
          map (
            word:
            let
              naming = lib.filter (set: says word set.text) sets;
            in
            {
              holds = naming == [ ];
              broke = "${name}'s ${lib.concatMapStringsSep ", " (set: set.where) naming} names ${word}.";
            }
          ) shopifyWords
        )
      );

      # Both machines' git reads the ignores home-manager writes, core's among
      # them, which an excludes file of their own would stop it reading, and
      # names no commit template, which git refuses a commit for when it's gone.
      git-reads-cores-ignores = holds "git-reads-cores-ignores" (
        onEachMachine (
          name: machine:
          let
            inherit ((git machine)) settings;
          in
          [
            {
              holds = !(settings ? core.excludesFile);
              broke = "${name}'s git names its own excludes file.";
            }
            {
              holds = !(settings ? commit.template);
              broke = "${name}'s git names a commit template.";
            }
          ]
        )
      );

      # Both machines commit as Joel outside work, and sign every commit, as
      # core's signing tells git in the include it writes last.
      one-personal-git = holds "one-personal-git" (
        onEachMachine (
          name: machine:
          let
            signing = lib.findFirst (include: include ? contents.gpg.format) { } (git machine).includes;
          in
          [
            {
              holds = (git machine).settings.user.email == "joel@grrbrr.ca";
              broke = "${name}'s git commits as another email than joel@grrbrr.ca.";
            }
            {
              holds = signing.contents.commit.gpgSign or false;
              broke = "${name}'s git doesn't sign every commit.";
            }
          ]
        )
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
