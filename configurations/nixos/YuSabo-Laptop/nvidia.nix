# Optimus 構成 (Intel UHD 630 + NVIDIA Quadro T2000 Mobile) の GPU 設定。
# 移行元: ラップトップの ~/nix-config/modules/nixos/nvidia/default.nix を踏襲。
#
# 実機の結線:
#   card0 = nvidia … 外部出力 (DP-1/2/3, HDMI-A-1)
#   card1 = i915   … 内蔵パネル (eDP-1)
#
# つまり外部ディスプレイは dGPU 側にぶら下がっている。PRIME offload にすると
# 消費電力は下がるが外部出力が使えなくなるため、実績のある「nvidia を
# プライマリドライバにして両方ロード」の構成をそのまま持ってきている。
# 省電力を詰めたくなったら prime.offload / prime.sync を検討する。
{ config, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # Turing 世代なので open カーネルモジュールも動くはずだが、
    # 現に proprietary で動いている構成を変えない。
    open = false;

    # サスペンド復帰時の VRAM 復元。有効にすると復帰が不安定になる報告があり、
    # 移行元でも無効だったため踏襲する。
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
