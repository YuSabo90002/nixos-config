{ pkgs, lib, ... }: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = pkgs.unstable.hyprland;
    portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
  };

  # グリーター(regreet)をCage上で起動
  programs.regreet = {
    enable = true;
    cageArgs = [ "-s" "-m" "last" ];

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
