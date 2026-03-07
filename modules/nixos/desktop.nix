{ pkgs, lib, flake, ... }:
let
  inherit (flake) inputs;
  system = pkgs.stdenv.hostPlatform.system;

  wallpaperSrc = builtins.fetchurl {
    url = "https://w.wallhaven.cc/full/9o/wallhaven-9o2rzk.jpg";
    sha256 = "02q56klyc5n7q1x3pxysc4dqj44k9rs4lwrcc5xdxpzjir3viqzs";
  };

  # hyprlock風にブラー＋減光した壁紙を事前生成
  blurredWallpaper = pkgs.runCommand "greeter-wallpaper" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    magick ${wallpaperSrc} \
      -resize 2560x1440^ -gravity center -extent 2560x1440 \
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

  # グリーター: AGS v3 + astal-greet を Hyprland(stable) 上で起動
  services.greetd = {
    enable = true;
    settings.default_session.command =
      "${pkgs.hyprland}/bin/Hyprland -c /etc/greetd/hyprland.conf";
  };

  environment.etc."greetd/hyprland.conf".text = ''
    monitor = DP-1, preferred, auto, 1
    monitor = DP-2, disable
    env = GREETER_SESSION_CMD,${sessionScript}
    exec-once = ${pkgs.swaybg}/bin/swaybg -i ${blurredWallpaper}/wallpaper.jpg -m fill
    exec-once = ${greeterAgs}/bin/ags run -d ${../../ags/greeter}; ${pkgs.hyprland}/bin/hyprctl dispatch exit
    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
    }
  '';

  # hyprlock用PAM認証
  security.pam.services.hyprlock = {};

  programs.steam = {
    enable = true;
    package = pkgs.unstable.steam;
    dedicatedServer.openFirewall = true;
    remotePlay.openFirewall = true;
  };

  # AMD GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
