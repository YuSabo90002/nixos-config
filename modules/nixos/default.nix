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
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # ブートローダー
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # KMSCON: TTYで日本語表示可能なターミナル
  services.kmscon = {
    enable = true;
    hwRender = true;
    fonts = [
      { name = "HackGen Console NF"; package = pkgs.hackgen-nf-font; }
    ];
    extraConfig = "font-size=16";
  };

  # システムパッケージ
  environment.systemPackages = with pkgs; [
    bubblewrap
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

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  # direnv + nix-direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # zram swap
  zramSwap.enable = true;
  boot.kernel.sysctl."vm.swappiness" = 180;

  system.stateVersion = "25.11";
}
