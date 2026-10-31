# The SSH keys that sign Joel's commits, as their public halves: his own,
# each behind Touch ID, a PIN or 1Password, and his agents', which sign
# with nobody asked. git trusts both (home.nix); a machine updating itself
# trusts only his own beside GitHub's merges, so no agent's commit alone
# can change what a machine runs.
{
  joel = [
    # 1Password-held ed25519, which signed before the Secure Enclave did.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu"
    # methuselah's Secure Enclave: joel-signing (Touch ID).
    "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBP/+4vmV9jofa+NC1HONKq//dKeeLk5BGswU6Jod45hIkac0NHyXwaYSO/Js7h34ceJfQB2ReQrE+BGcQPcGH60AAAAEc3NoOg=="
    # penelope's TPM, made by core's guide on 2026-10-25: joel-signing (its
    # PIN).
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBESjVkN/tSPAJweRv3fOrntjOA5oqCzUi6n9V7jqXSKPTPtfsqQgUjFpQPpedzShpgqRkbJKLwLTaY6g/X6vEIY="
  ];
  agents = [
    # methuselah's Secure Enclave: agent-signing.
    "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBNBQUgGis2mignI9aGhDFOi7MMHjIgFCN7abqcsquQDsnjnYGAn7YyHtQPkg/0GDDyx994qyzJ7tSqea0x/hBxEAAAAEc3NoOg=="
    # penelope's TPM: agent-signing.
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAKy/GVdnQYujyvYnzwc+AwH+HcZdT9U2jnF9xotfm/5cR01wwsViK6QTwoQbKHcgCcUyixzfYLM7/ClDDX5PTM="
  ];
}
