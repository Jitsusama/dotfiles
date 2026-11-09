# What every personal NixOS machine adds to core.nix's roles: the personal
# modules in every account, and the budget pi's turns draw on. 1Password,
# niri and the rest come with the roles.
{ homeModules }:
{
  home-manager.sharedModules = [
    homeModules.personal
    {
      # pi here runs on Joel's own Claude plan (modules/pi), so spend-watch
      # counts its turns against that plan rather than as one budget at list
      # prices. Which plan it is, and its limits, are the sign-in's to say: a
      # machine whose Claude Code is signed in adds the plan's feed, which
      # reads them. It's on NixOS alone, since spend-watch runs only on Linux.
      jitsusama.spend-watch.budgets.claude = {
        label = "Claude plan";
        kind = "plan";
        whose = "own";
        default = true;
        providers = [ "claude-code" ];
      };
    }
  ];
}
