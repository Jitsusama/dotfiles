# Joel's account on penelope: Chrome, its link to methuselah, what it
# declares to work placed there, the work sessions its own may ask, its
# panel's variable refresh and saturation, and the
# home-manager release it was set up with. Commits are signed with keys
# sealed in its TPM, as core's signing module says, which the guide made at
# its first start; the personal modules list them among the allowed
# signers.
{ pkgs, ... }:
{
  home.packages = [ pkgs.google-chrome ];

  # penelope dials methuselah, whose Remote Login is on, so the two carry
  # each other's sessions; nixos.nix pins methuselah's host key, and
  # methuselah pins penelope's agents' key to the link.
  jitsusama.mycelium.links = [ "methuselah.local" ];
  # What work placed here can count on wherever the laptop goes.
  jitsusama.mycelium.declares.reach = [ "internet" ];

  # A personal session here may ask work sessions for something, as one on
  # methuselah may: the node keeps the message until its links carry it to
  # optimus, where it crosses into work. Without it the node refuses with
  # no_flow.
  jitsusama.mycelium.flows = [
    {
      from = "personal";
      to = "work";
    }
  ];

  # The panel, Sharp's LQ135P1JX51, takes any refresh from 20 to 60 Hz, so
  # niri refreshes it only when something on it changes. On battery, idle,
  # that drew 6.48 W against 6.66 W at a fixed 60 Hz (2026-11-03). It's the
  # panel's, so it belongs to core's Surface module once a hardware module
  # can set a screen's lines; until then penelope, the one Surface, says it.
  jitsusama.niri.outputs."eDP-1" = [ "variable-refresh-rate" ];

  # The panel's primaries are sRGB's, so niri shows it accurately, and
  # beside a vivid screen Joel found it insanely washed out (2026-11-07). Shown more colourful in the display engine; the Dell
  # beside it stays accurate. Chosen by eye with him.
  jitsusama.niri.panelSaturation = 1.25;

  home.stateVersion = "24.05";
}
