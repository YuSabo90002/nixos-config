# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Deploy Commands

```bash
# Rebuild and switch to new configuration
nix run .#activate

# Update all flake inputs
nix flake update

# Update a specific input
nix flake update <input-name>

# Validate configuration
nix flake check
```

## Architecture

This is a single-host NixOS flake configuration for `Yuta-PC` (x86_64-linux, AMD CPU/GPU).

### Flake Structure

`flake.nix` uses **nixos-unified** (`mkLinuxSystem`) to wire together NixOS system modules and home-manager. Key inputs: `nixpkgs` (nixos-unstable), `home-manager`, `disko` (disk partitioning), `agenix` (secrets).

An overlay exposes `nixpkgs-unstable` as `pkgs.unstable` for packages that need the bleeding-edge channel.

### Module Layout

- **`nixos/`** — System-level NixOS modules
  - `default.nix` — Root module; imports all others, defines user, bootloader, SSH, nix settings
  - `desktop.nix` — Hyprland (via UWSM), tuigreet, PipeWire audio, AMD GPU
  - `locale.nix` — ja_JP.UTF-8, Asia/Tokyo, fcitx5-skk, CJK fonts
  - `networking.nix` — systemd-networkd, iwd, DNS (Cloudflare/Google fallback)
  - `hardware-configuration.nix` — Kernel modules, CPU microcode
  - `disko-config.nix` — btrfs on NVMe (subvolumes: @, @home, @nix, @log) + separate games drive

- **`home/`** — Home-manager configuration (single `default.nix`)
  - User packages, Hyprland keybinds/settings, git config, waybar, fcitx5

- **`secrets/`** — agenix-encrypted secrets (user password)

### Desktop Stack

Hyprland (Wayland tiling WM) with: waybar (bar), wofi (launcher), dunst (notifications), alacritty (terminal), swww (wallpaper), grim+slurp (screenshots). Japanese input via fcitx5-skk.

## Language and Conventions

- All NixOS/home-manager configuration is written in Nix
- User comments and commit messages are in Japanese
- `stateVersion` is `25.11` for both system and home-manager
- `mutableUsers = false` — user passwords managed via agenix, not `passwd`
