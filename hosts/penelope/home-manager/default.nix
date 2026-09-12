{
  pkgs,
  lib,
  username,
  homeDirectory,
  ...
}:
{
  home = {
    inherit username homeDirectory;

    packages = with pkgs; [
      _1password-gui
      _1password-cli
      google-chrome
      sherlock-launcher
    ];
  };

  programs = {
    ghostty.enable = true;

    git = {
      # Set here now that the shared module no longer picks a signer.
      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/BMnlV4qQolgj1SVcNFkhVJfMPk/sbMcfAjZreUmeu";
      settings.gpg.ssh.program = lib.mkForce "${pkgs._1password-gui}/share/1password/op-ssh-sign";
    };

    ssh.extraConfig = ''
      Host *
        IdentityAgent ~/.1password/agent.sock
    '';
  };
}
