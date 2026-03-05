{ pkgs, inputs, config, ... }: {
  imports = [
    inputs.ags.homeManagerModules.default
    ./hyprland.nix
    ./xdg.nix
    ./shell.nix
    ./terminal.nix
    ./editors.nix
  ];

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
    grim
    slurp
    wl-clipboard

    llm-agents.claude-code
    unstable.discord
    pavucontrol
    winboat
    unstable.gh
    unstable.uv
    unstable.volta
    specify-cli
    nmap

    # Rust nightly ツールチェーン (fenix)
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    fenix.rust-analyzer
  ];

  programs.ags = {
    enable = true;
    configDir = ../../ags;
    extraPackages = with inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}; [
      hyprland
      wireplumber
      mpris
      notifd
      tray
    ];
  };

  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 400;
      show = "drun";
      prompt = "";
      allow_images = true;
      image_size = 24;
      insensitive = true;
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 14px;
      }

      window {
        background-color: rgba(39, 40, 34, 0.92);
        border: 2px solid #A6E22E;
        border-radius: 10px;
      }

      #input {
        margin: 8px;
        padding: 8px 12px;
        border: none;
        border-bottom: 2px solid #75715E;
        background-color: #1e1f1c;
        color: #F8F8F2;
        border-radius: 6px;
      }

      #input:focus {
        border-bottom-color: #A6E22E;
      }

      #outer-box {
        margin: 4px;
      }

      #scroll {
        margin: 4px 8px;
      }

      #entry {
        padding: 6px 8px;
        border-radius: 6px;
        color: #F8F8F2;
      }

      #entry:selected {
        background-color: rgba(166, 226, 46, 0.2);
        color: #A6E22E;
      }

      #text {
        color: #F8F8F2;
      }

      #text:selected {
        color: #A6E22E;
      }
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user.Name = "yuta";
      user.email = "yusabo90002@gmail.com";
      core.editor = "nvim";
      credential.helper = "!${pkgs.unstable.gh}/bin/gh auth git-credential";
    };
  };

  # AGSバー（UWSMセッションに連動）
  systemd.user.services.ags = {
    Unit = {
      Description = "AGS (Aylur's GTK Shell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${config.programs.ags.finalPackage}/bin/ags run";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";
}
