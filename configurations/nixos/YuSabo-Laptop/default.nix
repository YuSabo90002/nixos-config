{
  flake,
  config,
  lib,
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
    ./nvidia.nix
    ../../../modules/nixos/laptop.nix
  ];

  # home-manager
  home-manager.extraSpecialArgs = {
    inherit inputs;
  };
  home-manager.users.yuta = {
    imports = [ flake.self.homeModules.default ];
    # 移行元のホームは 23.11 で作られている。上げてはいけない値。
    home.stateVersion = "23.11";
  };

  networking.hostName = "YuSabo-Laptop";

  # 持ち出す機体なので IPv6 は殺さない (自宅固有の抑制は Yuta-PC だけ)
  my.suppressIPv6 = false;

  # 内蔵パネル 1 枚。workspaces は敢えて空にしてある。1 画面のホストで
  # 全ワークスペースを内蔵パネルに固定すると、外部ディスプレイを挿しても
  # そこへ持っていけるワークスペースが無くなるため。
  # 未定義の出力はキャッチオール規則 (modules/home/hyprland.nix) で拾う。
  my.monitors = [
    {
      output = "eDP-1";
      width = 1920;
      height = 1080;
      primary = true;
    }
  ];

  # zram に加えて 32G の実 swap パーティションがある。共有側の 180 は zram 前提の
  # 値で、そのままだと zram を使い切った後にディスクへ積極的に swap しに行く。
  boot.kernel.sysctl."vm.swappiness" = 60;

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

    # 移行元から引き継ぎ。ISO 焼き用。
    pkgs.ventoy-full
    pkgs.keyutils
  ];

  # ventoy はバイナリブロブを含むため knownVulnerabilities が付いており、
  # 明示的に許可しないと評価が落ちる。nixpkgs 更新でバージョンが上がったら
  # ここの文字列も追随させること。
  nixpkgs.config.permittedInsecurePackages = [ "ventoy-1.1.12" ];

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

  # 移行元のシステムは 24.11 で構築されている。上げてはいけない値。
  system.stateVersion = "24.11";
}
