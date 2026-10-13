# Joel's account on methuselah: the Secure Enclave keys that sign its
# commits, and OmniWM tiling its windows.
{
  imports = [ ./secure-enclave.nix ];

  programs.omniwm.enable = true;
  home.stateVersion = "24.05";
}
