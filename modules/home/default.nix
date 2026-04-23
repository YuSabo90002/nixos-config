{ pkgs, inputs, config, ... }:
let
  inherit (inputs.self.packages.${pkgs.stdenv.hostPlatform.system})
    claude-code-seccomp
    ;
in {
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
    unstable.librewolf
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight
    chromium
    ripgrep
    fd
    jq
    btop
    grim
    slurp
    wl-clipboard

    llm-agents.claude-code
    unstable.discord
    unstable.pear-desktop
    pavucontrol

    unstable.gh
    unstable.uv
    unstable.volta
    nmap
    drawio
    unstable.ouch

    (unstable.lutris.override {
      extraPkgs = p: with p; [
        wineWow64Packages.staging
        winetricks
        gamescope
        mangohud
        gamemode
        vulkan-tools
      ];
    })

    unstable.prismlauncher

    nautilus
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

  # Claude Code sandbox: seccompバイナリをnpmグローバル探索パスに配置
  # Claude Codeがsettings.jsonのパスを読まないバグの回避策
  home.file.".npm/lib/node_modules/@anthropic-ai/sandbox-runtime/vendor/seccomp/x64/apply-seccomp".source =
    "${claude-code-seccomp}/bin/apply-seccomp";
  home.file.".npm/lib/node_modules/@anthropic-ai/sandbox-runtime/vendor/seccomp/x64/unix-block.bpf".source =
    "${claude-code-seccomp}/share/claude-code-seccomp/unix-block.bpf";

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";
}
