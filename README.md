# Dotfiles

A declarative macOS development environment using Nix flakes, nix-darwin, and home-manager with [core.nix](https://github.com/Jitsusama/core.nix) integration.

## What This Is

This replaces traditional package managers (Homebrew) and dotfile management with a single, reproducible configuration that manages both system settings and user packages declaratively.

## Quick Start

```bash
# Clone Configuration
git clone https://github.com/Jitsusama/dotfiles.git ~/.config/nix
cd ~/.config/nix

# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate

# Bootstrap System Configuration
nix develop -c sudo darwin-rebuild switch --flake .#methuselah

# Apply User Configuration  
nix develop -c home-manager switch --flake .#jitsusama
```

## References

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Home Manager](https://nix-community.github.io/home-manager)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [core.nix](https://github.com/Jitsusama/core.nix) - Shared configuration library
