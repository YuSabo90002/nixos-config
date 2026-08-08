{ pkgs, lib, osConfig, ... }:
let
  # モニター構成は NixOS 側の config.my.monitors (modules/nixos/monitors.nix) が
  # 唯一の出どころ。ここでは hyprland / hyprpaper / hyprlock 向けに展開するだけ。
  monitors = osConfig.my.monitors;
  primary = lib.head (lib.filter (m: m.primary) monitors);

  # 全モニターを囲む矩形。壁紙はこのサイズに引き伸ばしてから各モニターの
  # 位置で切り出すことで、複数画面にまたがった 1 枚の絵になる。
  # 1 画面のホストでは切り出しが画像全体と一致し、ただのリサイズに縮退する。
  spanWidth = lib.foldl' (acc: m: lib.max acc (m.x + m.width)) 0 monitors;
  spanHeight = lib.foldl' (acc: m: lib.max acc (m.y + m.height)) 0 monitors;
  spanRes = "${toString spanWidth}x${toString spanHeight}";

  wallpaperSrc = builtins.fetchurl {
    url = "https://w.wallhaven.cc/full/9o/wallhaven-9o2rzk.jpg";
    sha256 = "02q56klyc5n7q1x3pxysc4dqj44k9rs4lwrcc5xdxpzjir3viqzs";
  };

  # モニターごとの壁紙。ファイル名はコネクタ名 (DP-1.jpg 等)。
  splitWallpapers = pkgs.runCommand "split-wallpapers" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    mkdir -p $out
    magick ${wallpaperSrc} -resize ${spanRes}^ \
      -gravity center -extent ${spanRes} resized.jpg
    ${lib.concatMapStringsSep "\n" (m:
      "magick resized.jpg -crop ${toString m.width}x${toString m.height}+${toString m.x}+${toString m.y} +repage $out/${m.output}.jpg"
    ) monitors}
  '';

  wallpaperFor = m: "${splitWallpapers}/${m.output}.jpg";

  # hyprland.lua に前置するモニター定義とワークスペース割り当て。
  # 静的な hypr/hyprland.lua からはこの 2 ブロックを外してある。
  monitorLua = ''
    ------------------
    ---- モニター ----
    ------------------
    -- ホスト設定 (my.monitors) から生成。直接編集しないこと。
    ${lib.concatMapStringsSep "\n" (m:
      ''hl.monitor({ output = "${m.output}", mode = "${toString m.width}x${toString m.height}@${toString m.refresh}", position = "${toString m.x}x${toString m.y}", scale = ${toString m.scale} })''
    ) monitors}

    ------------------------------
    ---- ワークスペース (モニタ別) ----
    ------------------------------
    ${lib.concatMapStringsSep "\n" (m:
      lib.concatImapStringsSep "\n" (i: ws:
        ''hl.workspace_rule({ workspace = "${toString ws}", monitor = "${m.output}"${lib.optionalString (i == 1) ", default = true"} })''
      ) m.workspaces
    ) monitors}

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
    extraConfig = monitorLua + builtins.readFile ../../hypr/hyprland.lua;
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
        path = wallpaperFor primary;
        blur_passes = 3;
        blur_size = 7;
        brightness = 0.7;
        vibrancy = 0.2;
      };

      input-field = {
        monitor = primary.output;
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
          monitor = primary.output;
          text = "$TIME";
          color = "rgba(248, 248, 242, 1)";
          font_size = 64;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        {
          monitor = primary.output;
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
      wallpaper = map (m: {
        monitor = m.output;
        path = wallpaperFor m;
        fit_mode = "cover";
      }) monitors;
    };
  };
}
