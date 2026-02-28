{
  flake,
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (flake) inputs;
in
{
  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      };
    })
  ];

  imports = [
    inputs.disko.nixosModules.disko
    inputs.agenix.nixosModules.default
    ../../modules/nixos/disko-config.nix
    ../../modules/nixos/hardware-configuration.nix
    ../../modules/nixos/locale.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/desktop.nix
  ];

  # home-manager
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };
  home-manager.users.yuta = {
    imports = [ flake.self.homeModules.default ];
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Yuta-PC";

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
  age.secrets = {
    yuta-password = {
      file = ../../secrets/yuta-password.age;
    };
  };

  users.mutableUsers = false;
  users.users.yuta = {
    hashedPasswordFile = config.age.secrets.yuta-password.path;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGaCUEm+2Pw0mntn5pySflqtS+ao+TOTOaTmJGx5UQm8 yuta@Yuta-PC"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    wget
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "25.11";
}
