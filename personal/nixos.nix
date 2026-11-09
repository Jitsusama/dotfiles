# What every personal NixOS machine adds to core.nix's roles: the personal
# modules in every account, and the budget pi's turns draw on. 1Password,
# niri and the rest come with the roles.
{ homeModules }:
{
  home-manager.sharedModules = [
    homeModules.personal
    (
      { lib, options, ... }:
      {
        # pi here runs on Joel's own Claude plan (modules/pi), so spend-watch
        # counts its turns against that plan rather than as one budget at list
        # prices. His plan is Max 5x, at $100 a month, so that's its price; its
        # title and its limits are the sign-in's to say: a machine whose Claude
        # Code is signed in adds the plan's feed, which reads them. It's on
        # NixOS alone, since spend-watch runs only on Linux, and only where
        # core's roles bring spend-watch, which this module's own check, on a
        # bare NixOS, doesn't.
        config = lib.optionalAttrs (options ? jitsusama.spend-watch) {
          jitsusama.spend-watch.budgets.claude = {
            label = "Claude plan";
            kind = "plan";
            whose = "own";
            default = true;
            providers = [ "claude-code" ];
            price.dollars = 100;
          };
        };
      }
    )
  ];
}
