{ pkgs, inputs, ... }: {
  imports = [
    inputs.nixvim.homeModules.default
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # nixvim 同梱の matched nixpkgs を明示。home-manager の pkgs (nixpkgs-unstable)
    # と nixvim のバージョンがズレることによる source 警告を抑止する
    nixpkgs.source = inputs.nixvim.inputs.nixpkgs;
    # host/buildPlatform を文字列で明示する。nixvim の HM ラッパーは既定で
    # ホスト(home-manager=26.05)の elaborate 済みプラットフォーム
    # (`pkgs.stdenv.{host,build}Platform`)を継承するが、それを nixvim 同梱
    # nixpkgs(26.11)の lib.systems.elaborate に再投入すると、26.05 由来の属性に残る
    # `linux-kernel`(26.11 で削除済み) で評価エラーになる。文字列を渡せば 26.11 側で
    # 素から elaborate される。
    nixpkgs.hostPlatform = "x86_64-linux";
    nixpkgs.buildPlatform = "x86_64-linux";

    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      ignorecase = true;
      smartcase = true;
      clipboard = "unnamedplus";
    };

    globals.mapleader = " ";

    # Monokai Pro カラースキーム
    extraPlugins = [ pkgs.vimPlugins.monokai-pro-nvim ];
    extraConfigLuaPre = ''
      require("monokai-pro").setup({
        transparent_background = true,
        filter = "pro",
      })
      vim.cmd("colorscheme monokai-pro")
    '';

    # Treesitter
    plugins.treesitter = {
      enable = true;
      highlight.enable = true;
    };

    # Telescope（ファイル検索・grep）
    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>ff" = { action = "find_files"; options.desc = "ファイル検索"; };
        "<leader>fg" = { action = "live_grep"; options.desc = "テキスト検索"; };
        "<leader>fb" = { action = "buffers"; options.desc = "バッファ一覧"; };
      };
    };

    # Oil.nvim（ファイラー）
    plugins.oil = {
      enable = true;
      settings.view_options.show_hidden = true;
    };
    keymaps = [
      { key = "-"; action = "<cmd>Oil<cr>"; options.desc = "ファイラーを開く"; }
    ];

    # Nix LSP
    plugins.lsp = {
      enable = true;
      servers.nixd = {
        enable = true;
        settings.formatting.command = [ "nixfmt" ];
      };
    };

    # 補完
    plugins.cmp = {
      enable = true;
      settings = {
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
        mapping = {
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<C-Space>" = "cmp.mapping.complete()";
        };
      };
    };

    # Gitsigns
    plugins.gitsigns.enable = true;

    # アイコン
    plugins.web-devicons.enable = true;

    # lualine（ステータスライン）
    plugins.lualine = {
      enable = true;
      settings.options.theme = "monokai-pro";
    };
  };

  programs.zed-editor = {
    enable = true;
    package = pkgs.unstable.zed-editor;
    extraPackages = [ pkgs.nixd pkgs.nixfmt ];

    extensions = [ "nix" ];

    userSettings = {
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      vim_mode = false;
      ui_font_size = 16;
      buffer_font_size = 14;
      buffer_font_family = "JetBrains Mono";
      theme = {
        mode = "dark";
        dark = "One Dark";
        light = "One Light";
      };
      terminal = {
        shell = {
          program = "${pkgs.bashInteractive}/bin/bash";
        };
      };
      languages = {
        Nix = {
          language_servers = [ "nixd" ];
          formatter = {
            external = {
              command = "nixfmt";
              arguments = [ ];
            };
          };
        };
      };
      lsp = {
        nixd = {
          binary = {
            path = "${pkgs.nixd}/bin/nixd";
          };
        };
      };
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode;
    mutableExtensionsDir = false;
    profiles.default = {
      extensions = [
        pkgs.vscode-marketplace.ms-ceintl.vscode-language-pack-ja
        pkgs.vscode-marketplace.anthropic.claude-code
        pkgs.vscode-marketplace.jnoortheen.nix-ide
      ];
      userSettings = {
        "claudeCode.preferredLocation" = "panel";
        "claudeCode.claudeProcessWrapper" = "${pkgs.llm-agents.claude-code}/bin/claude";
        "claudeCode.allowDangerouslySkipPermissions" = true;

        # 統合ターミナルの bash を bashInteractive に固定する。
        # 親プロセス（nushell 等）の PATH を継承して devShell の素 bash を拾うと
        # readline 無しのため PS1 の `\[\]` が崩れるのを防ぐ。
        "terminal.integrated.profiles.linux" = {
          bash = {
            path = "${pkgs.bashInteractive}/bin/bash";
          };
        };
        "terminal.integrated.defaultProfile.linux" = "bash";
      };
    };
  };

  # VSCode (Electron) は XDG_CURRENT_DESKTOP=Hyprland を未知のデスクトップと判定し、
  # 使用するパスワードストアを自動選択できず「OSキーリングを識別できませんでした」
  # 警告を出す。gnome-keyring の Secret Service は起動済みなので、明示的に
  # gnome-libsecret を使うよう argv.json で指定する（home-manager の vscode
  # モジュールは settings.json のみ管理し argv.json は触らないため home.file で管理）。
  home.file.".vscode/argv.json".text = builtins.toJSON {
    "enable-crash-reporter" = true;
    "locale" = "ja";
    "password-store" = "gnome-libsecret";
  };
}
