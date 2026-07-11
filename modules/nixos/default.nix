{ config, lib, pkgs, flake, ... }:
let
  inherit (flake) inputs;
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;

  # PTY を持たない環境(Claude Code 等)から `sudo -A` で GUI パスワード入力を
  # 出すための askpass。fuzzel の password モードを使い、入力をそのまま stdout
  # へ返す。fuzzel は systemPackages には出さず、このスクリプトの依存として引く。
  sudoAskpass = pkgs.writeShellScript "sudo-askpass" ''
    exec ${pkgs.fuzzel}/bin/fuzzel --dmenu --password --lines 0 \
      --prompt "''${SUDO_PROMPT:-sudo password: }"
  '';
in {
  imports = [
    ./desktop.nix
    ./locale.nix
    ./networking.nix
    ./hardware-configuration.nix
    ./disko-config.nix
    ./hori-wheel.nix
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

    # 30日より古い世代を毎週刈る。古い世代のブートエントリも次回 activate で
    # 消えるため store ↔ /boot を揃える。/boot 512M の逼迫対策(下の
    # configurationLimit と併用)。
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true; # store の重複排除
  };

  # ブートローダー
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # /boot(512M FAT)に残すブートエントリ数。世代が無制限に溜まると /boot が
  # 溢れて新カーネルを含む rebuild が ENOSPC で失敗するため上限を設ける。
  boot.loader.systemd-boot.configurationLimit = 20;

  # KMSCON: TTYで日本語表示可能なターミナル
  services.kmscon = {
    enable = true;
    hwRender = true;
    fonts = [
      { name = "HackGen Console NF"; package = pkgs.hackgen-nf-font; }
    ];
    extraConfig = "font-size=16";
  };

  # claude-code-seccomp の share/ をシステムプロファイルに含める
  environment.pathsToLink = [ "/share/claude-code-seccomp" ];

  # システムパッケージ
  environment.systemPackages = with pkgs; [
    bubblewrap
    socat
    (callPackage ../../packages/claude-code-seccomp {})
    git
    wget
    usbutils # lsusb 等
  ];

  # `sudo -A` 用 GUI パスワードプロンプト (fuzzel ベース、上の let を参照)。
  environment.sessionVariables.SUDO_ASKPASS = "${sudoAskpass}";

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
