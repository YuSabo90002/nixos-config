{ pkgs, inputs, config, ... }: {
  imports = [
    inputs.ags.homeManagerModules.default
    ./hyprland.nix
    ./xdg.nix
    ./shell.nix
    ./terminal.nix
    ./editors.nix
    ./tmux.nix
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
    unstable.ytmdesktop
    pavucontrol

    unstable.gh
    unstable.uv
    unstable.volta
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
      apps
      hyprland
      wireplumber
      mpris
      notifd
      tray
    ];
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  # ランチャーはAGSに統合済み（ags/widget/Launcher.tsx）

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
