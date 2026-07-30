{ pkgs, ... }:
let
  wallpaperSrc = builtins.fetchurl {
    url = "https://w.wallhaven.cc/full/9o/wallhaven-9o2rzk.jpg";
    sha256 = "02q56klyc5n7q1x3pxysc4dqj44k9rs4lwrcc5xdxpzjir3viqzs";
  };

  # 二画面スパン壁紙: 元画像を各モニター解像度に合わせて分割
  # DP-1: 2560x1440 (左), DP-2: 1920x1080 (右)
  splitWallpapers = pkgs.runCommand "split-wallpapers" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    # 元画像を4480x1440にリサイズ（中央クロップ）
    magick ${wallpaperSrc} -resize 4480x1440^ \
      -gravity center -extent 4480x1440 resized.jpg
    # 左側: DP-1用 (2560x1440)
    magick resized.jpg -crop 2560x1440+0+0 +repage $out/left.jpg
    # 右側: DP-2用 (1920x1080, 上揃え)
    magick resized.jpg -crop 1920x1080+2560+0 +repage $out/right.jpg
  '';
in {
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua"; # 26.05+ の新デフォルト。設定本体は hypr/hyprland.lua に直書き
    package = pkgs.unstable.hyprland; # NixOSモジュール側と同じunstable版を使用
    # 既定だとベース 26.05 の xdph に unstable の hyprland を注入した派生
    # (finalPortalPackage = portalPackage.override { hyprland = finalPackage; })
    # になりキャッシュに存在せず毎回ローカルビルド + NixOS 側の 1.4.0 と二重に入る。
    # unstable を明示すると override が既定引数と同一になり NixOS 側と同じ派生に収束する。
    portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
    systemd.enable = false; # UWSMが管理するため無効化
    settings = { }; # 構造化設定は使わない（中身は hyprland.lua へ）
    # 実 Lua ファイルを取り込む。extraConfig!="" により module が hyprland.lua を生成し
    # onChange=reloadConfig（hyprctl reload）が自動付与される。
    extraConfig = builtins.readFile ../../hypr/hyprland.lua;
  };

  # hyprlock: ロック画面
  programs.hyprlock = {
    enable = true;
    package = pkgs.unstable.hyprlock;
    settings = {
      general = {
        grace = 3;
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = {
        path = "${splitWallpapers}/left.jpg";
        blur_passes = 3;
        blur_size = 7;
        brightness = 0.7;
        vibrancy = 0.2;
      };

      input-field = {
        monitor = "DP-1";
        size = "300, 50";
        outline_thickness = 3;
        dots_size = 0.2;
        dots_spacing = 0.15;
        outer_color = "rgba(166, 226, 46, 0.8)";
        inner_color = "rgba(62, 61, 50, 0.8)";
        font_color = "rgb(248, 248, 242)";
        fade_on_empty = true;
        placeholder_text = "";
        fail_color = "rgba(249, 38, 114, 0.8)";
        fail_text = "";
        position = "0, -20";
        halign = "center";
        valign = "center";
      };

      label = [
        {
          monitor = "DP-1";
          text = "$TIME";
          color = "rgba(248, 248, 242, 1)";
          font_size = 64;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "DP-1";
          text = "cmd[60000] date +'%m/%d (%a)'";
          color = "rgba(117, 113, 94, 1)";
          font_size = 20;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 140";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # hypridle: アイドル管理
  services.hypridle = {
    enable = true;
    package = pkgs.unstable.hypridle;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on && sleep 2 && systemctl --user restart ags.service";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
          on-resume = "";
        }
      ];
    };
  };

  services.hyprpaper = {
    enable = true;
    package = pkgs.unstable.hyprpaper;
    settings = {
      splash = false;
      # hyprpaper 0.8.0+ はブロック構文。旧 `preload=` / `wallpaper=monitor,path`
      # フラット構文は廃止され、起動時に黙殺される (「Monitor ... has no target」)。
      wallpaper = [
        {
          monitor = "DP-1";
          path = "${splitWallpapers}/left.jpg";
          fit_mode = "cover";
        }
        {
          monitor = "DP-2";
          path = "${splitWallpapers}/right.jpg";
          fit_mode = "cover";
        }
      ];
    };
  };
}
