# LLM Instructions for Nix Configuration Repository

## SYSTEM CONTEXT
Repository Type: Personal Nix flake configuration (macOS)
Architecture: aarch64-darwin
Primary Function: Declarative system + user environment management
Core Dependencies: nix-darwin, home-manager, core.nix library

## CRITICAL CONSTRAINTS
1. NEVER commit configurations that belong in core.nix
2. System hostname: `methuselah` | User config: `jitsusama`
3. Local configurations OVERLAY core.nix (extend, don't replace)
4. Always test locally before promoting to core.nix

## FILE STRUCTURE & ROLES
```
├── flake.nix                     → ORCHESTRATES: inputs, outputs, dev shell
├── nixpkgs.nix                   → PACKAGES: overlays, allowUnfree, platform
├── modules/                      → PERSONAL SHARED: configs for all personal machines
│   ├── nix-darwin/default.nix    → SYSTEM: personal macOS preferences  
│   └── home-manager/default.nix  → USER: personal packages + programs
└── hosts/methuselah/             → HOST-SPECIFIC: overrides for this machine
    ├── nix-darwin/default.nix    → SYSTEM: methuselah-specific overrides
    └── home-manager/default.nix  → USER: methuselah-specific overrides
```

## DECISION TREE: Configuration Placement

```
NEW CONFIGURATION REQUEST →
├── Is it sharable across work/personal?
│   ├── YES → Stage locally, test, then promote to core.nix
│   └── NO → Determine scope and placement
├── Is it shared across personal machines?
│   ├── YES → Add to modules/ (personal shared)
│   └── NO → Add to hosts/methuselah/ (host-specific)
├── Where to place in chosen scope?
│   ├── System-level → nix-darwin module
│   ├── User packages/programs → home-manager module
│   └── Package overrides → nixpkgs.nix (root level)
└── Has programs.* support?
    ├── YES → Use programs.* (preferred)
    └── NO → Add to packages list
```

## Common Commands

### Development Shell
```bash
nix develop               # Enter management shell with darwin-rebuild and home-manager available
nix develop -c <command>  # Run command in development shell environment
```

### Apply Configurations
```bash
sudo darwin-rebuild switch --flake .#methuselah  # Apply system changes
home-manager switch --flake .#jitsusama          # Apply user environment changes
```

### Bootstrap (First Time Only)
```bash
nix develop -c sudo darwin-rebuild switch --flake .#methuselah
nix develop -c home-manager switch --flake .#jitsusama
```

### Configuration Management
When adding packages, determine placement:
- **Tools with `programs.*` support** → Configure in `home.nix` programs section (preferred)
- **CLI tools without program support** → Add to `home.nix` packages
- **System-wide tools/fonts** → Add to `darwin.nix` environment.systemPackages (rarely needed due to core.nix)

**Testing changes:**
```bash
git add .                                       # REQUIRED: Stage changes for flake to see them
sudo darwin-rebuild build --flake .#methuselah  # After darwin.nix changes
home-manager build --flake .#jitsusama          # After home.nix changes
```

**Important:** Most common tools are already provided by core.nix. Check core.nix documentation before adding packages locally.

## Claude Code Guidance

### Quick Actions
- **Testing configuration changes**: Use the commands above after editing files
- **Adding packages**: Follow the package placement guidelines - most tools go in `home.nix` packages
- **Debugging**: Use `nix develop` to get into an environment with all tools available

### Common Tasks
When asked to:
- **Add a new tool**: Check if it has `programs.*` support first, then add to appropriate section
- **Update dependencies**: Run `nix flake update` in project root
- **Fix configuration errors**: Check that system architecture is `aarch64-darwin` and hostnames match
- **Modify system settings**: Most macOS defaults are handled by core.nix, local overrides go in `darwin.nix`

### File Modifications
- **Prefer editing existing configurations** over creating new files
- **Always test changes** with the appropriate switch command
- **Remember the hostname**: System config uses `methuselah`, user config uses `jitsusama`

## Configuration Management Philosophy

### What Goes Where
- **core.nix** (`~/src/github.com/jitsusama/core.nix/`): Shared configuration between work and personal life
  - Common development tools and programs
  - Standard program configurations (git, shell tools, etc.)
  - macOS system defaults
  - Universal packages and settings

- **Local repository** (this repo): Personal-only overrides and additions
  - Personal email, signing keys, specific hostnames
  - Machine-specific configurations
  - Local development environment tweaks
  - **NEVER commit sharable configurations here**

### Development Workflow

#### Testing New Shared Configuration (Do NOT Commit)
1. **Stage locally** for testing:
   ```bash
   # Add new configuration to local files (darwin.nix or home.nix)
   git add .                                        # REQUIRED: Stage changes for flake
   # Test the changes
   sudo darwin-rebuild switch --flake .#methuselah  # for system changes
   home-manager switch --flake .#jitsusama          # for user changes
   ```

2. **Verify it works** as intended

3. **DO NOT COMMIT** - these are staging changes only

#### Moving to core.nix (Permanent Solution)
1. **Create branch in core.nix**:
   ```bash
   cd ~/src/github.com/jitsusama/core.nix/
   git checkout -b feature/your-new-config
   ```

2. **Move configuration** from local files to appropriate core.nix modules

3. **Commit and push**:
   ```bash
   git add .
   git commit -m "Add new shared configuration"
   git push origin feature/your-new-config
   ```

4. **Create PR and merge** in core.nix repository

5. **Update local flake**:
   ```bash
   cd ~/.config/nix/
   nix flake update core
   ```

6. **Apply updated configuration**:
   ```bash
   sudo darwin-rebuild switch --flake .#methuselah
   home-manager switch --flake .#jitsusama
   ```

7. **Clean up local staging** - remove any temporary configurations from local files

### Important Rules
- **Local overlays on top of core.nix** - this repo extends, doesn't replace
- **Test locally first** - never commit untested changes to core.nix
- **Never commit shared configs locally** - they belong in core.nix
- **Use staging workflow** - local testing → core.nix PR → flake update → apply

## COMMAND REFERENCE

### APPLY CHANGES
```bash
# System changes (darwin.nix modifications)
sudo darwin-rebuild switch --flake .#methuselah

# User changes (home.nix modifications)  
home-manager switch --flake .#jitsusama

# Test without applying (REQUIRES: git add . first)
sudo darwin-rebuild build --flake .#methuselah
home-manager build --flake .#jitsusama

# Development shell access
nix develop                    # Interactive shell
nix develop -c <command>       # Run command in shell
```

### BOOTSTRAP (First Time Only)
```bash
nix develop -c sudo darwin-rebuild switch --flake .#methuselah
nix develop -c home-manager switch --flake .#jitsusama  
```

## TASK EXECUTION PATTERNS

### PATTERN: Add Package
```
IF user requests new package:
  1. Check: Does it have programs.* support?
     YES → Add to home.nix programs section
     NO → Add to home.nix packages list
  2. Determine scope: Sharable or personal-only?
     SHARABLE → Stage locally, test, promote to core.nix
     PERSONAL → Commit to local repo
  3. Stage and test: git add . && home-manager switch --flake .#jitsusama
  4. If staging → DO NOT COMMIT, follow core.nix workflow
```

### PATTERN: System Configuration
```
IF user requests system settings:
  1. Check: Already handled by core.nix?
     YES → Override in darwin.nix if needed
     NO → Add to darwin.nix
  2. Stage and test: git add . && sudo darwin-rebuild switch --flake .#methuselah
  3. Determine if sharable → follow promotion workflow if yes
```

### PATTERN: Core.nix Promotion
```
WHEN configuration should be shared:
  1. Stage in local files (darwin.nix OR home.nix)
  2. Stage and test locally: git add . && appropriate switch command
  3. VERIFY functionality
  4. cd ~/src/github.com/jitsusama/core.nix/
  5. git checkout -b feature/descriptive-name
  6. Move config from local → core.nix modules
  7. git commit + push + create PR
  8. After merge: nix flake update core (in ~/.config/nix/)
  9. Apply: darwin-rebuild/home-manager switch
  10. Clean local staging files (git restore --staged . if needed)
```

## SCOPE CLASSIFICATION

### BELONGS IN core.nix (~/src/github.com/jitsusama/core.nix/)
- Development tools (languages, editors, build tools)
- Shell utilities and modern Unix replacements  
- Standard program configurations (git basics, shell setup)
- macOS system defaults and preferences
- Universal packages used across environments

### BELONGS IN LOCAL modules/ (shared across personal machines)
- Personal-specific packages and programs
- Personal email, SSH keys, signing configurations
- Personal program preferences (themes, settings)
- Personal development tools and language servers

### BELONGS IN LOCAL hosts/methuselah/ (host-specific only)
- Machine-specific hostnames and identifiers
- Hardware-specific configurations
- Performance tuning for this specific machine
- Local development environment overrides

### TEMPORARY STAGING (DO NOT COMMIT)
- Configurations being tested before promotion to core.nix
- Experimental settings and packages
- Work-in-progress configurations

## ERROR PREVENTION

### CRITICAL CHECKS
- **ALWAYS `git add .` before testing** - flakes only see committed/staged files
- Always use correct hostnames: `methuselah` (system) | `jitsusama` (user)
- Never commit staging configurations to this repository
- Always test locally before promoting to core.nix
- Verify architecture is `aarch64-darwin`
- Use `programs.*` when available, fallback to packages

### COMMON MISTAKES TO AVOID  
- **Forgetting `git add .` before testing** - causes "path does not exist" errors
- Committing shared configs locally instead of promoting
- Wrong hostname in commands (causes build failures)
- Adding packages without checking programs.* support
- Not testing before promotion to core.nix
- Creating new files instead of editing existing ones 
