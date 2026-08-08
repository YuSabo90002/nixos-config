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
  nixpkgs.overlays = import ../../../overlays { inherit inputs; };

  imports = [
    inputs.disko.nixosModules.disko
    inputs.agenix.nixosModules.default
    ../../../modules/nixos

    # このホスト固有
    ./hardware.nix
    ./disko.nix
    ../../../modules/nixos/hori-wheel.nix # HORI トラックホイール (デスクトップのみ)
  ];

  # home-manager
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };
  home-manager.users.yuta = {
    imports = [ flake.self.homeModules.default ];
  };

  networking.hostName = "Yuta-PC";

  # 2 画面 (左 2560x1440 / 右 1920x1080、上揃え)。奇数ワークスペースを左、
  # 偶数を右に割り当てる。
  my.monitors = [
    {
      output = "DP-1";
      width = 2560;
      height = 1440;
      x = 0;
      primary = true;
      workspaces = [ 1 3 5 7 9 ];
    }
    {
      output = "DP-2";
      width = 1920;
      height = 1080;
      x = 2560;
      workspaces = [ 2 4 6 8 10 ];
    }
  ];

  # agenix
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
  age.secrets = {
    yuta-password = {
      file = ../../../secrets/yuta-password.age;
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
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGaCUEm+2Pw0mntn5pySflqtS+ao+TOTOaTmJGx5UQm8 yuta@Yuta-PC"
    ];
  };
}
