{ pkgs, lib, ... }: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  programs.uwsm.enable = true;

  # グリーター(regreet)をHyprland上で起動し、DP-2を無効にする
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
        background-color: rgba(39, 40, 34, 0.85);
      }

      entry {
        background-color: #3E3D32;
        color: #F8F8F2;
        border-radius: 10px;
        border: 1px solid #75715E;
      }

      button {
        background-color: #A6E22E;
        color: #272822;
        border-radius: 10px;
        font-weight: bold;
      }

      button:hover {
        background-color: #B8F33E;
      }

      label {
        color: #F8F8F2;
      }

      .error label {
        color: #F92672;
      }

      combobox button {
        background-color: #3E3D32;
        color: #F8F8F2;
      }

      combobox button:hover {
        background-color: #49483E;
      }
    '';
  };
  services.greetd.settings.default_session.command = lib.mkForce
    "dbus-run-session ${pkgs.hyprland}/bin/start-hyprland -- -c /etc/greetd/hyprland.conf";
  environment.etc."greetd/hyprland.conf".text = ''
    monitor = DP-1, preferred, auto, 1
    monitor = DP-2, disable
    exec-once = ${lib.getExe pkgs.regreet}; hyprctl dispatch exit
    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
    }
  '';

  programs.steam = {
    enable = true;
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
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
