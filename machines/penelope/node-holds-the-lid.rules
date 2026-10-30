// Joel's account may hold off sleep and the lid's handling with a block,
// from outside a session, so mycelium's node, a service of his, keeps
// penelope awake with its lid shut while it runs work. Inside a session
// logind lets him already; this lets the node too, and nothing else of
// logind's. polkit's own engine reads this, in the JavaScript it knows.
polkit.addRule(function (action, subject) {
  if (
    (action.id === "org.freedesktop.login1.inhibit-block-sleep" ||
      action.id === "org.freedesktop.login1.inhibit-handle-lid-switch") &&
    subject.user === "jitsusama"
  ) {
    return polkit.Result.YES;
  }
  return polkit.Result.NOT_HANDLED;
});
