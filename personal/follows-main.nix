# What every personal machine that updates itself follows, on NixOS and on
# a Mac alike: this repository's main, with core.nix at its own main rather
# than where the lock last pinned it. Joel's account follows both and asks
# whenever either moves, so no update waits on him or on a lock bump. main
# counts only when GitHub signed it merging a change (its key,
# github-merges.asc, from github.com/web-flow.gpg), or Joel did with a key of
# his own; an agent's key alone never moves a machine. Each machine says
# which of its outputs to build and when a switch is whole. A machine
# without core's update-to-main takes none of it.
{
  config,
  lib,
  options,
  ...
}:
let
  signers = import ./signers.nix;
  mergers = {
    openpgp = [ ./github-merges.asc ];
    ssh = map (
      key: ''${config.home-manager.users.jitsusama.jitsusama.identity.email} namespaces="git" ${key}''
    ) signers.joel;
  };
in
{
  config = lib.optionalAttrs (options ? jitsusama.update-to-main) {
    jitsusama.update-to-main = {
      repository = "https://github.com/Jitsusama/dotfiles";
      signers = mergers;
      follows.core = {
        repository = "https://github.com/Jitsusama/core.nix";
        signers = mergers;
      };
      askers = [ "jitsusama" ];
      follower = "jitsusama";
    };
  };
}
