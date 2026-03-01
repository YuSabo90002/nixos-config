{ config, lib, pkgs, flake, ... }:
let
  inherit (flake) inputs;
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in {
  imports = [
    ./desktop.nix
    ./locale.nix
    ./networking.nix
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # Nix設定
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # ブートローダー
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # システムパッケージ
  environment.systemPackages = with pkgs; [
    git
    wget
  ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  system.stateVersion = "25.11";
}
