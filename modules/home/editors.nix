{ pkgs, inputs, ... }: {
  imports = [
    inputs.nixvim.homeModules.default
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

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
      settings.highlight.enable = true;
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
      };
    };
  };
}
