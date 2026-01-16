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

    git.settings = {
      gpg.ssh.program = lib.mkForce "${pkgs._1password-gui}/share/1password/op-ssh-sign";
    };

    ssh.extraConfig = ''
      Host *
        IdentityAgent ~/.1password/agent.sock
    '';
  };
}
