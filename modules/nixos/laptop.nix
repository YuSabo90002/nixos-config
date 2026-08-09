# ラップトップ共通の設定。デスクトップには不要なので modules/nixos/default.nix には
# 入れず、configurations/nixos/<ホスト名>/ 側から明示的に import する。
{ config, lib, pkgs, ... }:
let
  th = config.my.batteryChargeThresholds;
in
{
  options.my.batteryChargeThresholds = lib.mkOption {
    type = lib.types.nullOr (lib.types.submodule {
      options = {
        start = lib.mkOption {
          type = lib.types.ints.between 0 99;
          description = "この残量を下回るまで充電を再開しない (%)。";
        };
        stop = lib.mkOption {
          type = lib.types.ints.between 1 100;
          description = "この残量で充電を止める (%)。start より大きいこと。";
        };
      };
    });
    default = null;
    description = ''
      リチウムイオン電池の充電上限・再開閾値。null なら OS からは触らない。

      満充電で繋ぎっぱなしにすると劣化が速いので、据え置き運用が長い機体では
      80% 前後で止めると寿命が延びる。代償として可搬時の実効容量が減るため、
      長距離を持ち出す前は一時的に 100 へ上げるとよい:
        echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold

      ThinkPad (thinkpad_acpi) では閾値が EC 側に保存され再起動しても残るので、
      udev の add イベントで一度書けば足りる。
    '';
  };

  config = lib.mkMerge [
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

      # 温度管理。Intel 専用 (AMD 機で有効にすると起動に失敗する) なので、
      # Intel マイクロコードを入れているホストでだけ有効にする。hardware.nix が
      # ベンダに応じて cpu.<vendor>.updateMicrocode を立てるので、これが実質の
      # 「この機体は Intel か」判定になる。
      #
      # ただし Intel でも、ファームウェア側に独自の熱制御を持つ機種
      # (Lenovo DYTC 等) では thermald が自ら起動を降りる。そういう機体は
      # ホスト側で false にすること。
      services.thermald.enable = lib.mkDefault config.hardware.cpu.intel.updateMicrocode;

      # UEFI・Thunderbolt コントローラ等のファームウェア更新 (LVFS)。
      # ThinkPad はベンダが LVFS に載せているので `fwupdmgr update` で当てられる。
      # 自動では何も更新しない。
      services.fwupd.enable = true;

      # 指紋認証。fprintd を有効にすると security.pam.services.*.fprintAuth が
      # 既定で全 PAM サービスに付き、pam_unix より前に sufficient で挿さる。
      # 「パスワードを PAM 会話に流し込む」タイプのフロントエンドはこれと相性が
      # 悪いので、下で個別に外している。
      #
      # 登録は実機で: fprintd-enroll (指を変えるなら -f right-index-finger 等)
      # 確認は: fprintd-verify
      services.fprintd.enable = true;

      # グリーター (AGS greeter) は Greet.login() でパスワード文字列を渡すだけで、
      # 「指を置け」という PAM プロンプトに応答できない。挿さると指紋待ちで
      # ログインが固まるのでログイン画面はパスワード専用にする。
      security.pam.services.greetd.fprintAuth = false;

      # hyprlock も同様に PAM 会話へパスワードを流す作りだが、こちらは fprintd を
      # D-Bus で直接叩く実装を自前で持っている (auth:fingerprint:enabled、
      # modules/home/hyprland.nix 側で有効化)。PAM 経由と二重になると衝突するので
      # PAM 側は外し、hyprlock 内蔵の実装に一本化する。
      security.pam.services.hyprlock.fprintAuth = false;
    }

    (lib.mkIf (th != null) {
      assertions = [
        {
          assertion = th.start < th.stop;
          message = "my.batteryChargeThresholds: start (${toString th.start}) は stop (${toString th.stop}) より小さくすること。";
        }
      ];

      # start → stop の順で書くこと。現在値が start より小さい stop になっている
      # 場合、逆順だとカーネルに弾かれる。
      # ATTR{...}=="?*" は「その属性が存在する電池だけ」に当てるためのガード。
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT[0-9]", ATTR{charge_control_start_threshold}=="?*", ATTR{charge_control_start_threshold}="${toString th.start}", ATTR{charge_control_end_threshold}="${toString th.stop}"
      '';
    })
  ];
}
