# ラップトップ共通の設定。デスクトップには不要なので modules/nixos/default.nix には
# 入れず、configurations/nixos/<ホスト名>/ 側から明示的に import する。
{ pkgs, ... }:
{
  # 電源プロファイル切り替え。TLP のほうが電池は持つが、こちらは D-Bus に
  # プロファイルを出すので AGS のステータスパネルから素直に叩ける。
  # TLP とは同時に有効化できない (どちらも同じ sysfs を触る)。
  services.power-profiles-daemon.enable = true;

  # バッテリー残量・充電状態の供給元。AGS の AstalBattery がこれを見る。
  services.upower.enable = true;

  # 蓋を閉じたらサスペンド。外部電源接続中も同じ挙動にする。
  # 外部ディスプレイ接続中 (Docked) だけは、閉じたまま使いたいので無視する。
  # 26.05 で services.logind.lidSwitch* は settings.Login.* へ移行した。
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # バックライト操作。同梱の udev ルールが /sys/class/backlight/*/brightness を
  # video グループ書き込み可にするので、ユーザーを video に入れる必要がある
  # (LED 用に input も見る)。
  environment.systemPackages = [ pkgs.brightnessctl ];
  services.udev.packages = [ pkgs.brightnessctl ];
  users.users.yuta.extraGroups = [ "video" "input" ];

  # NOTE: 温度管理の services.thermald は Intel 専用なので、実機の CPU ベンダが
  # 判明してから足すこと。AMD 機で有効にするとサービスが起動に失敗する。
}
