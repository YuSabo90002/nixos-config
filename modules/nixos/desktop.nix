{ config, pkgs, lib, flake, ... }:
let
  inherit (flake) inputs;
  system = pkgs.stdenv.hostPlatform.system;

  # モニター構成は config.my.monitors (modules/nixos/monitors.nix) が唯一の出どころ。
  primary = lib.head (lib.filter (m: m.primary) config.my.monitors);
  primaryRes = "${toString primary.width}x${toString primary.height}";

  # greetd 用 Hyprland の monitor 行
  greeterMonitorLines = lib.concatMapStringsSep "\n" (m:
    "monitor = ${m.output}, ${toString m.width}x${toString m.height}@${toString m.refresh}, ${toString m.x}x${toString m.y}, ${toString m.scale}"
  ) config.my.monitors;

  wallpaperSrc = builtins.fetchurl {
    url = "https://w.wallhaven.cc/full/9o/wallhaven-9o2rzk.jpg";
    sha256 = "02q56klyc5n7q1x3pxysc4dqj44k9rs4lwrcc5xdxpzjir3viqzs";
  };

  # hyprlock風にブラー＋減光した壁紙を事前生成 (主画面の解像度に合わせる)
  blurredWallpaper = pkgs.runCommand "greeter-wallpaper" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    magick ${wallpaperSrc} \
      -resize ${primaryRes}^ -gravity center -extent ${primaryRes} \
      -blur 0x21 -modulate 70 \
      $out/wallpaper.jpg
  '';

  # グリーター用AGS (専用flake input、astal-greetライブラリ付き)
  astalGreetPkg = inputs.astal-greeter.packages.${system}.greet;
  greeterAgs = inputs.ags-greeter.packages.${system}.ags.override {
    extraPackages = [ astalGreetPkg ];
  };

  # セッション起動スクリプト（Greet.login()が単一要素配列にするためラッパーが必要）
  sessionScript = pkgs.writeShellScript "greeter-session" ''
    exec uwsm start -e -D Hyprland hyprland.desktop
  '';
in
{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs.unstable.hyprland;
    portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
  };

  # Electron/Chromium アプリ (Discord・VSCode 等) を Wayland(ozone) で起動させる。
  # XWayland 起動だと画面共有が xdg-desktop-portal を呼ばず、Discord の
  # ウィンドウ共有ダイアログ (xdph ピッカー) が出なくなるため必須。
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # グリーター: AGS v3 + astal-greet を Hyprland(stable) 上で起動
  services.greetd = {
    enable = true;
    settings.default_session.command =
      "${pkgs.hyprland}/bin/Hyprland -c /etc/greetd/hyprland.conf";
  };

  environment.etc."greetd/hyprland.conf".text = ''
    ${greeterMonitorLines}
    env = GREETER_SESSION_CMD,${sessionScript}
    env = PRIMARY_MONITOR,${primary.output}
    exec-once = ${pkgs.swaybg}/bin/swaybg -i ${blurredWallpaper}/wallpaper.jpg -m fill
    exec-once = ${greeterAgs}/bin/ags run -d ${../../ags/greeter}; ${pkgs.hyprland}/bin/hyprctl dispatch exit
    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      disable_watchdog_warning = true
    }
  '';

  # hyprlock用PAM認証
  security.pam.services.hyprlock = {};

  # polkit: GUIアプリの特権操作を action 単位で許可判定する。
  # 認証エージェント本体は home-manager の services.hyprpolkitagent。
  # ルールは extraConfig に JS で書くのが NixOS 正規の方法
  # （security.polkit には構造化された rule オプションは存在せず、
  #  rules.d/*.rules は mozjs で評価される JS ファイルそのものであるため）。
  # wheel グループ（= yuta）に対し、以下を無認証で許可:
  #   - udisks2 全般（USB/外部ドライブのマウント/アンマウント等）
  #   - login1 の reboot/power-off/suspend（PowerMenu からの電源操作）
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel") && (
          action.id.indexOf("org.freedesktop.udisks2.") === 0 ||
          action.id == "org.freedesktop.login1.reboot" ||
          action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
          action.id == "org.freedesktop.login1.power-off" ||
          action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
          action.id == "org.freedesktop.login1.suspend" ||
          action.id == "org.freedesktop.login1.suspend-multiple-sessions"
      )) {
        return polkit.Result.YES;
      }
    });
  '';

  # Secret Service API (VSCode 等が libsecret 経由で使う)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  programs.steam = {
    enable = true;
    package = pkgs.unstable.steam;
    dedicatedServer.openFirewall = true;
    remotePlay.openFirewall = true;
  };

  # GPU。中身は mesa なので AMD/Intel どちらでもこのまま使える
  # (ベンダ固有なのは hardware.nix 側の microcode と kvm-* モジュール)。
  # enable32Bit は Steam 用。
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    package = pkgs.unstable.mesa;
    package32 = pkgs.unstable.pkgsi686Linux.mesa;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # PipeWire にリアルタイム優先度を取らせる。無いと負荷時に xrun が増えて
  # 音が途切れる。services.pipewire は rtkit を自動で有効にしないので明示する。
  security.rtkit.enable = true;

  # Bluetooth (UI は AGS の StatusPanel から制御)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  # nautilus 用: ゴミ箱・ネットワークマウント (gvfs) とサムネイル (tumbler)
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
