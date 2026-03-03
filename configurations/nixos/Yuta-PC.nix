{
  flake,
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
  nixpkgs.overlays = import ../../overlays { inherit inputs; };

  # unstable Hyprlandに合わせてモジュールもunstableから取得
  disabledModules = [
    "programs/wayland/hyprland.nix"
    "programs/wayland/uwsm.nix"
  ];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/hyprland.nix"
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/wayland/uwsm.nix"
    inputs.disko.nixosModules.disko
    inputs.agenix.nixosModules.default
    ../../modules/nixos
  ];

  # home-manager
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };
  home-manager.users.yuta = {
    imports = [ flake.self.homeModules.default ];
  };

  networking.hostName = "Yuta-PC";

  # agenix
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
  age.secrets = {
    yuta-password = {
      file = ../../secrets/yuta-password.age;
    };
  };

  environment.systemPackages = [
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # ユーザー定義
  users.mutableUsers = false;
  users.users.yuta = {
    hashedPasswordFile = config.age.secrets.yuta-password.path;
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGaCUEm+2Pw0mntn5pySflqtS+ao+TOTOaTmJGx5UQm8 yuta@Yuta-PC"
    ];
  };
}
