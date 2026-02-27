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
    alacritty
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
    settings = {
      monitor = [
        "DP-3,2560x1440@60,0x0,1"
        "DP-2,1920x1080@60,2560x0,1"
      ];
      "$mod" = "SUPER";
      "$terminal" = "alacritty";
      "$menu" = "wofi --show drun";
      exec-once = [
        "waybar"
        "dunst"
        "fcitx5"
      ];
      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $menu"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
      ];
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
      };
      input = {
        kb_layout = "us";
      };
    };
  };

  xdg.configFile = {
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

        [GroupOrder]
        0=Default
      '';
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
