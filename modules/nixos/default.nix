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
  # ホスト固有のもの (hardware / disko / 周辺機器) はここではなく
  # configurations/nixos/<ホスト名>/ 側から import する。
  imports = [
    ./desktop.nix
    ./locale.nix
    ./monitors.nix
    ./networking.nix
    ./tailscale.nix
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
    # 全インタフェースで 22 を開けない。下の tailscale0 限定ルールで代替し、
    # LAN/WAN 側からは接続不可にする。
    openFirewall = false;
  };

  # mosh。セッション確立は SSH 経由 (22) で、そこから UDP 60000-61000 に移る。
  # モジュールの openFirewall は既定 true かつ全インタフェースに穴を開けるので、
  # SSH と同じく tailnet 限定にするため明示的に切って下でインタフェース指定する。
  #
  # Tailscale SSH は netstack で 22 を終端するが $SSH_CONNECTION は素の sshd と
  # 同様に埋まる。よって mosh 既定の --bind-server=ssh_connection がそのまま通り、
  # mosh-server は tailscale IP に bind する (iPad から接続して確認済み)。
  # --bind-server=any の回避策は不要。
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };

  # SSH / mosh は tailnet 内からのみ許可。tailscale が落ちると remote から
  # 入れなくなる点は承知の上 (ローカル端末なのでコンソールから復旧できる)。
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 22 ];
    allowedUDPPortRanges = [
      {
        from = 60000;
        to = 61000;
      }
    ];
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

  # zram swap。180 は「圧縮メモリへの swap はページキャッシュ回収より安い」という
  # zram 前提の値なので、実ディスクの swap パーティションを持つホストでは効きすぎる
  # (zram を使い切った後に遅いディスクへ積極的に swap しに行く)。
  # そういうホストが下げられるよう mkDefault にしておく。
  zramSwap.enable = true;
  boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 180;

  system.stateVersion = "25.11";
}
