{ pkgs, lib, ... }: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs.unstable.hyprland;
    portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
  };

  # グリーター(regreet)をHyprland(stable)上で起動し、サブモニターを無効化
  programs.regreet = {
    enable = true;

    # フォント: JetBrainsMono Nerd Font 14pt
    font = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font";
      size = 14;
    };

    # TOML設定
    settings = {
      GTK.application_prefer_dark_theme = true;

      background = {
        path = builtins.fetchurl {
          url = "https://w.wallhaven.cc/full/8g/wallhaven-8geypo.png";
          sha256 = "1jv86k8bsqwsrnhhyqgyaybjklbndllg32a81anmffy0c87hcqay";
        };
        fit = "Cover";
      };

      appearance.greeting_msg = "おかえりなさい";

      widget.clock = {
        format = "%m/%d (%a) %H:%M";
      };
    };

    # Monokai配色のGTK4 CSS
    extraCss = ''
      window {
        background-color: rgba(39, 40, 34, 0.75);
      }

      /* メインコンテナ */
      box {
        color: #F8F8F2;
      }

      /* グリーティングメッセージ */
      label {
        color: #F8F8F2;
        font-weight: 400;
      }

      label.title {
        font-size: 28px;
        font-weight: bold;
        color: #A6E22E;
      }

      /* 時計 */
      label.clock {
        font-size: 48px;
        font-weight: bold;
        color: #F8F8F2;
      }

      /* 入力フィールド */
      entry {
        background-color: rgba(62, 61, 50, 0.6);
        color: #F8F8F2;
        border-radius: 12px;
        border: 2px solid rgba(166, 226, 46, 0.4);
        padding: 10px 16px;
        font-size: 16px;
        min-height: 20px;
      }

      entry:focus {
        border: 2px solid rgba(166, 226, 46, 0.9);
        background-color: rgba(62, 61, 50, 0.8);
      }

      /* ログインボタン */
      button {
        background-color: rgba(166, 226, 46, 0.85);
        color: #272822;
        border-radius: 12px;
        font-weight: bold;
        font-size: 15px;
        padding: 8px 24px;
        border: none;
        min-height: 20px;
      }

      button:hover {
        background-color: rgba(166, 226, 46, 1.0);
      }

      button:active {
        background-color: rgba(130, 180, 30, 1.0);
      }

      /* セッション/ユーザー選択 */
      combobox button,
      dropdown button {
        background-color: rgba(62, 61, 50, 0.6);
        color: #F8F8F2;
        border: 1px solid rgba(117, 113, 94, 0.5);
        font-weight: normal;
        font-size: 14px;
        padding: 6px 12px;
      }

      combobox button:hover,
      dropdown button:hover {
        background-color: rgba(62, 61, 50, 0.9);
        border: 1px solid rgba(166, 226, 46, 0.5);
      }

      /* エラーメッセージ */
      .error label {
        color: #F92672;
        font-weight: bold;
        font-size: 14px;
      }

      /* 電源ボタン類 */
      button.destructive-action {
        background-color: rgba(249, 38, 114, 0.7);
        color: #F8F8F2;
      }

      button.destructive-action:hover {
        background-color: rgba(249, 38, 114, 0.9);
      }
    '';
  };

  services.greetd.settings.default_session.command = lib.mkForce
    "${pkgs.hyprland}/bin/Hyprland -c /etc/greetd/hyprland.conf";
  environment.etc."greetd/hyprland.conf".text = ''
    monitor = DP-1, preferred, auto, 1
    monitor = DP-2, disable
    exec-once = ${lib.getExe pkgs.regreet}; ${pkgs.hyprland}/bin/hyprctl dispatch exit
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
