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

  # The bare machines are built from core.nix's own, as its checks build
  # theirs: the least machine of each class, with core's home-manager and
  # nixpkgs settings and one account, someone, for home-manager to
  # configure, with the given modules added. evaluates is core's check
  # that a machine evaluates and warns of nothing.
  bareNixos = modules: nixpkgs.lib.nixosSystem { modules = [ core.lib.bareNixosModule ] ++ modules; };
  bareDarwin =
    modules: nix-darwin.lib.darwinSystem { modules = [ core.lib.bareDarwinModule ] ++ modules; };
  evaluates = core.lib.evaluates pkgs;

  # Home-manager modules, given to the bare machine's one account.
  inAccount = modules: { home-manager.users.someone.imports = modules; };

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
        lib.mapAttrsToList (
          target: file: set "${option}.${target}" (target + toString (file.text or null))
        ) files;
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

      # Every code comment names only what exists, as core's do: a comment
      # naming a path from one of this repository's top folders that names
      # nothing fails.
      comments-name-what-exists = core.lib.commentsNameWhatExists pkgs { src = self; };

      # Every folder says what it holds, as core's do: in a README, the opening
      # comment of its entry file, a line of its parent's README opening with
      # its name, or for a top folder a line of the README's map.
      every-folder-says-what-it-holds = core.lib.everyFolderSaysWhatItHolds pkgs {
        src = self;
      };

      # Every code file past 800 lines and folder of more than 40 entries says
      # why it stays whole, as core's do.
      every-long-file-says-why = core.lib.everyLongFileSaysWhy pkgs { src = self; };

      # No program past five lines is written as a string in Nix, as core's
      # aren't: each lives in a file of its own, read by its linter.
      programs-live-in-their-own-files = core.lib.programsLiveInTheirOwnFiles pkgs { src = self; };

      # Every lint suppression says why where it's made, as core's do.
      every-suppression-says-why = core.lib.everySuppressionSaysWhy pkgs { src = self; };

      # Every shell script meets shellcheck's optional checks that find faults,
      # as core's do, beyond the ones the formatting check turns on.
      every-script-meets-shellcheck-at-its-strictest =
        core.lib.everyScriptMeetsShellcheckAtItsStrictest pkgs
          { src = self; };

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

      # methuselah keeps itself current as penelope does: Joel's account
      # follows this repository's main and core.nix's and asks whenever
      # either moves, rather than waiting for someone to ask it.
      methuselah-keeps-itself-current =
        let
          updates = methuselah.config.jitsusama.update-to-main;
        in
        holds "methuselah-keeps-itself-current" [
          {
            holds = updates.follower or null == "jitsusama";
            broke = "methuselah has no follower in Joel's account, so it updates only when asked.";
          }
          {
            holds = updates.follows ? core;
            broke = "methuselah doesn't follow core.nix's main, so it waits on a lock bump.";
          }
          {
            holds = methuselah.config.launchd.user.agents ? update-to-main-follows;
            broke = "methuselah runs no follower agent for Joel's account.";
          }
        ];

      # methuselah's Nix signs what it builds with the Mac's own key, which
      # core makes and names, so optimus takes its builds by trusting that key.
      methuselah-signs-what-it-builds =
        let
          inherit (methuselah) config;
        in
        holds "methuselah-signs-what-it-builds" [
          {
            holds = lib.hasInfix "!include signing.conf" config.nix.extraOptions;
            broke = "methuselah's Nix never reads signing.conf, so it signs nothing it builds.";
          }
          {
            holds = config.jitsusama.nix-daemon.label == config.launchd.daemons.nix-daemon.serviceConfig.Label;
            broke = "methuselah restarts a Nix daemon it doesn't run, so its own never reads the signing line.";
          }
        ];

      # methuselah builds what optimus's root sends it, which an agent may ask
      # for, only in Nix's sandbox, never relaxed, where a derivation could
      # ask its way out. A line in extraOptions would come after the setting
      # in nix.conf and win, so none there may name the sandbox.
      methuselah-sandboxes-what-it-builds =
        let
          inherit (methuselah.config) nix;
          inherit (nix.settings) sandbox;
        in
        holds "methuselah-sandboxes-what-it-builds" [
          {
            holds = builtins.isBool sandbox && sandbox;
            broke = "methuselah builds optimus's derivations outside Nix's sandbox, with the Mac's network and files.";
          }
          {
            holds = (nix.settings.sandbox-fallback or true) == false;
            broke = "methuselah builds without the sandbox when it can't set one up.";
          }
          {
            holds = !lib.hasInfix "sandbox" nix.extraOptions;
            broke = "methuselah's extraOptions names the sandbox, after and over its setting.";
          }
        ];

      # methuselah lets penelope's root through to its Linux VM to build, and
      # nothing more: its key forwards only to the VM, never to a session of
      # the builder account, which this Mac's Nix trusts.
      methuselah-lets-penelope-build =
        let
          inherit (methuselah) config;
          penelopes = lib.filter (lib.hasInfix "penelope root builds");
          lines = penelopes config.users.users.builder.openssh.authorizedKeys.keys;
        in
        holds "methuselah-lets-penelope-build" [
          {
            holds = penelopes config.jitsusama.linux-builder.authorizedKeys != [ ];
            broke = "methuselah's Linux VM doesn't let penelope's root in, so penelope builds everything itself.";
          }
          {
            holds = lines != [ ];
            broke = "methuselah's builder account doesn't let penelope's root jump through to the VM.";
          }
          {
            holds = lib.all (
              line: lib.hasPrefix "restrict," line && lib.hasInfix ''command="/usr/bin/false"'' line
            ) lines;
            broke = "penelope's key opens a session on methuselah's builder account, which the Mac's Nix trusts.";
          }
        ];

      # After a switch methuselah goes back to the system it left unless what
      # optimus leans on there comes back: the Linux VM, optimus's only native
      # aarch64 builder, and mycelium's links in Joel's account.
      methuselah-goes-back-without-its-builder-or-links =
        let
          health = map toString methuselah.config.jitsusama.update-to-main.health;
          names = label: lib.any (lib.hasInfix label) health;
        in
        holds "methuselah-goes-back-without-its-builder-or-links" [
          {
            holds = names methuselah.config.launchd.daemons.linux-builder-vz.serviceConfig.Label;
            broke = "methuselah keeps a switch whose Linux VM never came back, so optimus loses its aarch64 builder.";
          }
          {
            holds = names methuselah.config.home-manager.users.jitsusama.launchd.agents.mycelium.config.Label;
            broke = "methuselah keeps a switch whose mycelium agent never came back, so its links to optimus and penelope stay down.";
          }
        ];

      # methuselah keeps its own day's tally of what its unified log said, with
      # core's health started by launchd, so the loop reads the Mac's faults
      # and failing daemons from the Mac itself, as it does penelope's.
      methuselah-keeps-its-health =
        let
          home = methuselah.config.home-manager.users.jitsusama;
        in
        holds "methuselah-keeps-its-health" [
          {
            holds = home.launchd.agents ? health && home.launchd.agents.health.enable;
            broke = "methuselah runs no health agent in Joel's account, so nothing tallies what went wrong on it.";
          }
          {
            holds = lib.any (package: lib.getName package == "health") home.home.packages;
            broke = "methuselah has no health command for Joel to read the day's tally with.";
          }
        ];

      # penelope keeps its own day's tally of what its journals said, with
      # core's health, so the loop that makes it better reads its crashes,
      # device faults and failing services from the laptop itself.
      penelope-keeps-its-health =
        let
          home = penelope.config.home-manager.users.jitsusama;
        in
        holds "penelope-keeps-its-health" [
          {
            holds = home.systemd.user.services ? health;
            broke = "penelope runs no health daemon in Joel's account, so nothing tallies what went wrong on it.";
          }
          {
            holds = lib.any (package: lib.getName package == "health") home.home.packages;
            broke = "penelope has no health command for Joel to read the day's tally with.";
          }
        ];

      # optimus proves penelope as a builder every minute by logging in as
      # builder, and each login starts builder's user manager, which stops
      # 10 seconds after. A switch meeting one stopping fails that account's
      # activation, and update-to-main takes the whole machine back, as at
      # 10:02 on 14 November; lingering keeps that manager running.
      penelope-switches-while-optimus-builds = holds "penelope-switches-while-optimus-builds" [
        {
          holds = penelope.config.users.users.builder.linger == true;
          broke = "penelope starts and stops builder's user manager at each of optimus's logins, so a switch meeting one stopping goes back.";
        }
      ];

      # penelope's root reaches methuselah's Linux VM to build there, with a
      # key it makes once and the VM's host key pinned, as optimus does.
      penelope-reaches-methuselahs-builder =
        let
          inherit (penelope.config) programs system;
          key = "/etc/nix/methuselah-builder_ed25519";
        in
        holds "penelope-reaches-methuselahs-builder" [
          {
            holds = lib.hasInfix "IdentityFile ${key}" programs.ssh.extraConfig;
            broke = "penelope's ssh doesn't sign in to methuselah's builder with root's builder key.";
          }
          {
            holds = lib.hasInfix "-f ${key}" (system.activationScripts.methuselah-builder-key.text or "");
            broke = "penelope never makes the key its ssh signs in to methuselah's builder with.";
          }
          {
            holds = programs.ssh.knownHosts ? methuselah-linux;
            broke = "penelope doesn't pin the host key of methuselah's Linux VM, so ssh refuses it.";
          }
        ];

      # penelope's updates send their heavy pieces to methuselah's Linux VM,
      # building here only what it can't take, and still in batches, since the
      # daemon's worker grows with a build's pieces wherever they build.
      penelope-builds-on-methuselah =
        let
          inherit (penelope.config.jitsusama) update-to-main;
        in
        holds "penelope-builds-on-methuselah" [
          {
            holds = update-to-main.elsewhere;
            broke = "penelope's updates build every piece on the laptop.";
          }
          {
            holds = lib.hasPrefix "ssh-ng://methuselah-linux " (toString update-to-main.builders);
            broke = "penelope's updates don't send their heavy pieces to methuselah's Linux VM.";
          }
          {
            holds = update-to-main.here != null;
            broke = "penelope's updates fail away from home, where methuselah's VM can't be reached, rather than building on the laptop.";
          }
          {
            holds = update-to-main.batches != null;
            broke = "penelope's updates give one build every piece at once, which grew the daemon's worker past the laptop's memory.";
          }
          {
            holds = penelope.config.nix.settings.builders-use-substitutes or false;
            broke = "methuselah's VM gets every input from penelope over Wi-Fi rather than from the cache.";
          }
          {
            holds = !(lib.hasInfix "big-parallel" (toString update-to-main.builders));
            broke = "penelope's updates offer methuselah's Rosetta VM big-parallel work, such as its kernel, whose output penelope can't check, since only optimus's key and the cache's are trusted.";
          }
          {
            holds =
              penelope.config.nix.settings.extra-trusted-public-keys == [
                "optimus-1:kfGUJvh5HrsPAj6xUj7OqyJjATPJz0ouP98sRnjL4Uo="
              ];
            broke = "penelope trusts a key besides optimus's and the cache's, so a store path built elsewhere is taken as built by either.";
          }
        ];

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
          holds = lib.any (
            package: lib.getName package == "guide"
          ) penelope.config.environment.systemPackages;
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
            holds =
              !(lib.hasInfix "tuigreet" (lib.head (lib.splitString " " settings.default_session.command)));
            broke = "penelope's greeter is tuigreet alone.";
          }
        ];

      # penelope's launcher finds every kind of thing core gives it but those
      # named here as off on purpose, each with why. core turns a few places
      # on by another module's unit or option, named by a string, and when
      # one of those names changed, Home Network went off on every machine
      # while every check passed (eero-watch, renamed eero-daemon, found
      # 2026-11-11). core's every-place-is-on-where-its-source-is holds that
      # on a made-up machine; this holds it on penelope, so a place that goes
      # off here unasked fails naming it, and a reason no longer true does too.
      penelope-turns-on-every-launcher-place =
        let
          providers = (homeOf penelope).jitsusama.quickshell.launcher.providers;
          offOnPurpose = {
            warp = "penelope installs no WARP, so it has no WARP link to show.";
          };
          off = lib.attrNames (lib.filterAttrs (_: provider: !provider.enable) providers);
          unasked = lib.subtractLists (lib.attrNames offOnPurpose) off;
          backOn = lib.subtractLists off (lib.attrNames offOnPurpose);
        in
        holds "penelope-turns-on-every-launcher-place" [
          {
            holds = unasked == [ ];
            broke =
              "penelope's launcher has these places off with no reason given: "
              + "${lib.concatStringsSep ", " unasked}.";
          }
          {
            holds = backOn == [ ];
            broke =
              "penelope's launcher has these places on, though they're named as off on "
              + "purpose: ${lib.concatStringsSep ", " backOn}.";
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

      # Neither machine's Nix trusts a person's account, or a group one is in:
      # a trusted account sets the daemon's options that run as root, so
      # every program running as it, agents included, would be root without
      # a password. Only optimus's builds, through builder, are trusted.
      nix-trusts-no-person = holds "nix-trusts-no-person" (
        onEachMachine (
          name: machine:
          let
            beyond = lib.subtractLists [
              "root"
              "builder"
            ] machine.config.nix.settings.trusted-users;
          in
          [
            {
              holds = beyond == [ ];
              broke = "${name}'s Nix trusts ${lib.concatStringsSep ", " beyond}, beyond root and builder.";
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
