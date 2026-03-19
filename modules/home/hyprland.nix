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
    package = pkgs.unstable.hyprland; # NixOSモジュール側と同じunstable版を使用
    systemd.enable = false; # UWSMが管理するため無効化
    settings = {
      monitor = [
        "DP-1,2560x1440@60,0x0,1"
        "DP-2,1920x1080@60,2560x0,1"
      ];
      "$mod" = "SUPER";
      "$terminal" = "alacritty";
      "$menu" = "ags request -i yuta-shell toggle-launcher";

      # Monokai配色 + Dwindleレイアウト
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 3;
        "col.active_border" = "rgba(A6E22Eee) rgba(66D9EFee) 45deg";
        "col.inactive_border" = "rgba(75715Eaa)";
        resize_on_border = true;
        layout = "dwindle";
      };

      # 角丸・影・ブラー・不透明度
      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.92;
        dim_inactive = false;
        shadow = {
          enabled = true;
          range = 12;
          render_power = 3;
          color = "rgba(1a1a1aee)";
          offset = "0 4";
        };
        blur = {
          enabled = true;
          size = 3;
          passes = 2;
          new_optimizations = true;
          vibrancy = 0.2;
          noise = 0.02;
        };
      };

      # アニメーション
      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
        ];
        animation = [
          "windows, 1, 4, easeOutQuint, popin 80%"
          "windowsMove, 1, 4, easeInOutCubic"
          "fade, 1, 3, easeOutQuint"
          "workspaces, 1, 4, easeInOutCubic, slide"
          "border, 1, 5, easeOutQuint"
          "borderangle, 1, 30, linear, loop"
        ];
      };

      # Dwindleレイアウト設定
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      # 入力設定
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        accel_profile = "flat";
        numlock_by_default = false;
      };

      # トラックボールの速度設定
      device = {
        name = "kensington-expert-mouse";
        sensitivity = 0.8;
      };

      # その他
      misc = {
        focus_on_activate = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        force_default_wallpaper = 0;
      };

      # モニタ別ワークスペース (奇数=DP-1, 偶数=DP-2)
      workspace = [
        "1, monitor:DP-1, default:true"
        "2, monitor:DP-2, default:true"
        "3, monitor:DP-1"
        "4, monitor:DP-2"
        "5, monitor:DP-1"
        "6, monitor:DP-2"
        "7, monitor:DP-1"
        "8, monitor:DP-2"
        "9, monitor:DP-1"
        "10, monitor:DP-2"
      ];

      # キーバインド
      bind = [
        # 基本操作
        "$mod, Return, exec, $terminal"
        "$mod, P, exec, $menu"
        "$mod, C, killactive"
        "$mod, M, exit"
        "$mod CTRL, L, exec, loginctl lock-session"

        # レイアウト操作
        "$mod, V, layoutmsg, preselect d"
        "$mod, B, layoutmsg, preselect r"
        "$mod SHIFT, Space, togglefloating"
        "$mod, F, fullscreen"
        "$mod, D, pseudo"
        "$mod SHIFT, F, pin"

        # スクリーンショット
        "$mod, S, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mod SHIFT, S, exec, grim - | wl-copy"

        # ワークスペース切替
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # ウィンドウ移動
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # ワークスペース順送り/逆送り
        "$mod, Tab, workspace, m+1"
        "$mod SHIFT, Tab, workspace, m-1"

        # マウスホイールでワークスペース切替
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # フォーカス移動 (Vim風)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # ウィンドウ入替 (Vim風)
        "$mod SHIFT, H, swapwindow, l"
        "$mod SHIFT, L, swapwindow, r"
        "$mod SHIFT, K, swapwindow, u"
        "$mod SHIFT, J, swapwindow, d"
      ];

      # リサイズ (リピート可能)
      binde = [
        "$mod CTRL, H, resizeactive, -30 0"
        "$mod CTRL, L, resizeactive, 30 0"
        "$mod CTRL, K, resizeactive, 0 -30"
        "$mod CTRL, J, resizeactive, 0 30"
      ];

      # マウス操作
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # 自動起動
      exec-once = [
        "discord"
        "pear-desktop"
      ];

    }; # settings end

    # ウィンドウルール (0.53 named block構文)
    extraConfig = ''
      windowrule {
        name = pavucontrol-float
        match:class = pavucontrol
        float = true
      }
      windowrule {
        name = calculator-float
        match:class = org.gnome.Calculator
        float = true
      }
      windowrule {
        name = dialog-open-file
        match:title = ^(Open File)$
        float = true
      }
      windowrule {
        name = dialog-save-file
        match:title = ^(Save File)$
        float = true
      }
      windowrule {
        name = dialog-open-folder
        match:title = ^(Open Folder)$
        float = true
      }
      windowrule {
        name = steam-friends
        match:title = ^(Friends List)$
        float = true
      }
      windowrule {
        name = steam-settings
        match:title = ^(Steam Settings)$
        float = true
      }
      windowrule {
        name = steam-game
        match:class = ^steam_app_
        fullscreen = true
      }
      windowrule {
        name = discord-ws
        match:class = discord
        workspace = 10
      }
      windowrule {
        name = youtube-music-ws
        match:class = com.github.th_ch.youtube_music
        workspace = 10
      }
      windowrule {
        name = pip-float
        match:title = ^(Picture-in-Picture)$
        float = true
        pin = true
      }
    '';
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
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
          on-resume = "";
        }
      ];
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "${splitWallpapers}/left.jpg"
        "${splitWallpapers}/right.jpg"
      ];
      wallpaper = [
        "DP-1,${splitWallpapers}/left.jpg"
        "DP-2,${splitWallpapers}/right.jpg"
      ];
    };
  };
}
