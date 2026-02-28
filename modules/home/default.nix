{ pkgs, ... }: {
  home = {
    username = "yuta";
    homeDirectory = "/home/yuta";
    stateVersion = "25.11";
  };

  home.packages = with pkgs; [
    firefox
    ripgrep
    fd
    btop
    wofi
    waybar
    dunst
    grim
    slurp
    wl-clipboard
    swww
    unstable.claude-code
    unstable.discord
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false; # UWSMが管理するため無効化
    settings = {
      monitor = [
        "DP-1,2560x1440@60,0x0,1"
        "DP-2,1920x1080@60,2560x0,1"
      ];
      "$mod" = "SUPER";
      "$terminal" = "alacritty";
      "$menu" = "wofi --show drun";

      exec-once = [ "waybar" "dunst" "swww-daemon" ];

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
          size = 6;
          passes = 3;
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
        workspace = 4
      }
      windowrule {
        name = pip-float
        match:title = ^(Picture-in-Picture)$
        float = true
        pin = true
      }
    '';
  };

  # steamwebhelperがDRI_PRIME=1でクラッシュする問題の回避
  # https://github.com/ValveSoftware/steam-for-linux/issues/9383
  xdg.desktopEntries.steam = {
    name = "Steam";
    comment = "Application for managing and playing games on Steam";
    exec = "steam %U";
    icon = "steam";
    terminal = false;
    type = "Application";
    categories = [ "Network" "FileTransfer" "Game" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
  };

  xdg.configFile = {
    "fcitx5/config" = {
      force = true;
      text = ''
        [Hotkey/TriggerKeys]
        0=Control+Shift+T
      '';
    };
    "fcitx5/profile" = {
      force = true;
      text = ''
        [Groups/0]
        Name=Default
        Default Layout=us
        DefaultIM=skk

        [Groups/0/Items/0]
        Name=skk
        Layout=

        [Groups/0/Items/1]
        Name=
        Layout=us

        [GroupOrder]
        0=Default
      '';
    };
  };

  programs.nushell = {
    enable = true;
    settings = {
      show_banner = false;
      completions = {
        algorithm = "prefix";
        case_sensitive = false;
        quick = true;
        partial = true;
      };
    };
    shellAliases = {
      ll = "ls -l";
      la = "ls -a";
      lla = "ls -la";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$character";
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
      directory = {
        truncation_length = 3;
        style = "bold cyan";
      };
      git_branch = {
        style = "bold purple";
      };
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      terminal.shell = {
        program = "${pkgs.nushell}/bin/nu";
      };
      window = {
        padding = { x = 8; y = 8; };
        dynamic_padding = true;
        opacity = 0.93;
      };
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        bold = { family = "JetBrainsMono Nerd Font"; style = "Bold"; };
        size = 13.0;
      };
      cursor = {
        style = { shape = "Block"; blinking = "On"; };
        blink_interval = 500;
      };
      scrolling = {
        history = 10000;
      };
      colors = {
        primary = {
          background = "#272822";
          foreground = "#F8F8F2";
        };
        normal = {
          black   = "#272822";
          red     = "#F92672";
          green   = "#A6E22E";
          yellow  = "#F4BF75";
          blue    = "#66D9EF";
          magenta = "#AE81FF";
          cyan    = "#A1EFE4";
          white   = "#F8F8F2";
        };
        bright = {
          black   = "#75715E";
          red     = "#F92672";
          green   = "#A6E22E";
          yellow  = "#F4BF75";
          blue    = "#66D9EF";
          magenta = "#AE81FF";
          cyan    = "#A1EFE4";
          white   = "#F9F8F5";
        };
      };
    };
  };

  programs.git = {
    enable = true;
    settings ={
      user.Name = "yuta";
      user.email = "yusabo90002@gmail.com";  
    };
  };
  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";
}
