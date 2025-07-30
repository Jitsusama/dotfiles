# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Nix flake configuration** for managing a complete macOS development environment using:
- **nix-darwin** for system-wide macOS configuration
- **home-manager** for user-level package and program management
- A **flat file structure** following Nix community conventions

## Architecture

The configuration follows a **separation of concerns** approach:

- **`flake.nix`** - Entry point that orchestrates all configurations, defines inputs, system architecture (`aarch64-darwin`), and provides a development shell
- **`darwin.nix`** - macOS system-level configuration (system packages, macOS defaults, nix daemon settings)
- **`home.nix`** - User environment (packages, program configurations, dotfiles)
- **`nixpkgs.nix`** - Centralized nixpkgs configuration (overlays, allowUnfree, platform settings)

The flake uses `nixpkgs.legacyPackages.${system}` for accessing the full package set and passes configuration via `specialArgs`/`extraSpecialArgs` to make variables like `username` and `homeDirectory` available to modules.

## Key Design Decisions

- **Programs over packages**: Tools with dedicated `programs.*` support (like git, fzf, bat) are configured as programs rather than plain packages for better integration
- **System vs user packages**: Fonts go in `darwin.nix` system packages, while development tools go in `home.nix` user packages
- **Git configuration**: Fully managed including 1Password SSH signing, excludes files, and commit templates
- **Bootstrap compatibility**: Includes GID fix (`ids.gids.nixbld = 350`) for existing Nix installations

## Common Commands

### Development Shell
```bash
nix develop                           # Enter management shell with home-manager available
```

### Apply Configurations
```bash
home-manager switch --flake .        # Apply user environment changes
darwin-rebuild switch --flake .      # Apply system changes (after bootstrap)
```

### Bootstrap (First Time Only)
```bash
sudo nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#default
```

### Configuration Management
When adding packages, determine placement:
- **Tools with `programs.*` support** → Configure in `home.nix` programs section
- **CLI tools without program support** → Add to `home.nix` packages
- **System-wide tools/fonts** → Add to `darwin.nix` environment.systemPackages

Always run `darwin-rebuild switch --flake .` after system changes and `home-manager switch --flake .` after user changes to test the configuration builds correctly.