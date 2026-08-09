{ pkgs, inputs, config, lib, osConfig, ... }:
let
  # AGS に主モニターのコネクタ名を渡す (ags/app.tsx の MAIN_MONITOR)。
  primaryMonitor = (lib.head (lib.filter (m: m.primary) osConfig.my.monitors)).output;

  inherit (inputs.self.packages.${pkgs.stdenv.hostPlatform.system})
    claude-code-seccomp
    ;

  # unfree のため autoWire に乗らず pkgs/ 側に置いてある (pkgs/README.md 参照)
  moshi-hook = pkgs.callPackage ../../pkgs/moshi-hook { };
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
    # system.stateVersion と同様、ホームを最初に作った版に固定する値。
    # ホストごとに違うので mkDefault で上書き可能にする。
    stateVersion = lib.mkDefault "25.11";
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
    # Moshi (iOS ターミナル) のホスト側ヘルパー。クライアントが SSH 越しに
    # `command -v moshi-hook` で存在確認するので PATH に居る必要がある。
    moshi-hook
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
      # ラップトップ用。電池もバックライトも無いホストでは AGS 側が実行時に
      # 検出してウィジェットを出さないので、ライブラリはどのホストにも入れておく
      # (ホストごとに ags/ のソースを変えずに済ませるため)。
      battery
      brightness
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

  # moshi-hook の常駐。エージェントの hook が叩く Unix socket を張り、
  # 承認のやり取り用に Moshi へ WebSocket を維持する。
  # 上流の `moshi-hook service install` は ~/.config/systemd/user に命令的に
  # unit を書くので使わず、こちらで宣言的に持つ。
  # ペアリング済みの秘密は ~/.local/state/moshi/secrets.json (0600) にあり、
  # 実行時に書かれる可変状態なので home-manager の管理下には置かない。
  systemd.user.services.moshi-hook = {
    Unit = {
      Description = "Moshi hook daemon (agent hook socket + Moshi WebSocket bridge)";
      Documentation = "https://getmoshi.app/docs/hooks";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${moshi-hook}/bin/moshi-hook serve";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # PDF/DjVu/PS/コミックビューワ (キーボード駆動、装飾なし)
  # 同梱プラグイン: pdf-mupdf, djvu, ps, cb
  programs.zathura = {
    enable = true;
    options = {
      # GUI 要素は全部隠す ("c"=コマンドライン "s"=ステータスバー "h"/"v"=スクロールバー)。
      # `:` を押せばコマンドラインは一時的に出る
      guioptions = "";
      window-title-basename = true;
      statusbar-basename = true;
      render-loading = false;

      # 既定で反転表示にする (Ctrl+r でトグル)。色は Alacritty と同じ Monokai
      recolor = true;
      recolor-keephue = true; # 図表の色相は保つ
      recolor-lightcolor = "#272822";
      recolor-darkcolor = "#F8F8F2";
      default-bg = "#272822";
      default-fg = "#F8F8F2";
      statusbar-bg = "#272822";
      statusbar-fg = "#F8F8F2";
      inputbar-bg = "#272822";
      inputbar-fg = "#F8F8F2";
      highlight-color = "#F4BF75";
      highlight-active-color = "#F92672";
      font = "JetBrainsMono Nerd Font 11";

      adjust-open = "width"; # 論文は横幅合わせのほうが読みやすい
      scroll-page-aware = true;
      selection-clipboard = "clipboard";
      zoom-step = 10;
    };
    # キーバインドは既定の vim 風のまま (f=リンク follow, d=見開き, Ctrl+r=反転トグル,
    # Ctrl+n=ステータスバー一時表示, Tab=目次)
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
      Environment = [ "PRIMARY_MONITOR=${primaryMonitor}" ];
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
