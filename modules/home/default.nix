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
    llm-agents.claude-desktop
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    unstable.discord
    unstable.pear-desktop
    pavucontrol

    unstable.gh
    nodejs
    python3
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
    unstable.gamescope

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
      bluetooth
    ];
  };

  # 画像ビューワ (Wayland ネイティブ、装飾なし)
  programs.swayimg = {
    enable = true;
    settings = {
      general = {
        mode = "viewer";
        size = "image";   # 画像の実サイズにウィンドウを合わせる
        decoration = "no";
        app_id = "swayimg";
      };

      viewer = {
        window = "#00000000"; # 背景は透過
        scale = "optimal";
        antialiasing = "mks13";
      };

      # 1 枚開いても同ディレクトリの画像を送れるようにする
      list = {
        all = "yes";
        order = "numeric";
      };

      gallery = {
        size = "200";
        pstore = "yes"; # サムネイルを永続キャッシュ
      };

      # オーバーレイ表示は既定で消す (viewer 上で `i` でトグル)
      info.show = "no";

      "keys.viewer" = {
        # gallery は Return、slideshow は s (既定どおり)
        "Shift+g" = "mode gallery";
      };
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
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
  # ags/ 以下のファイル変更時にユニットファイル内容が変わるよう、
  # X-Restart-Triggers にディレクトリの store path を埋め込む。
  # これで sd-switch が変更を検知して home-manager switch 時に自動再起動する。
  systemd.user.services.ags = {
    Unit = {
      Description = "AGS (Aylur's GTK Shell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${../../ags}" ];
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

  # polkit認証エージェント（GUIアプリの権限昇格パスワードダイアログ用）。
  # UWSMが起動するgraphical-session.targetに連動して自動起動する
  # systemd user service を生成する（ags/hypridle と同パターン）。
  # unstable hyprland と歩調を合わせて package も unstable を使う。
  services.hyprpolkitagent = {
    enable = true;
    package = pkgs.unstable.hyprpolkitagent;
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
