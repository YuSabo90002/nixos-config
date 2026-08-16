{
  description = "Yuta-PC NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixos-unified.url = "github:srid/nixos-unified";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      # nixpkgs を follows させると nixvim (26.11) と nixpkgs-unstable (26.05) の
      # バージョン不整合警告が出るため、nixvim 同梱の matched nixpkgs を使わせる
      url = "github:nix-community/nixvim";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.astal.follows = "astal";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    # 複数コーディングエージェントを1ターミナルで多重化するPTYマルチプレクサ
    herdr = {
      url = "github:ogulcancelik/herdr";
    };

    zen-browser = {
      # 上流が nixos-unstable 前提 (ffmpeg_9 等) なので stable を follows させると
      # 引数不足で eval に失敗する
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # グリーター用 (コミットハッシュ固定、nix flake updateで更新されない)
    ags-greeter = {
      url = "github:aylur/ags/bbee2f18939f1ec7ff720e717cf305e73635628f";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.astal.follows = "astal-greeter";
    };
    astal-greeter = {
      url = "github:aylur/astal/d8738f97ed01f4d87f668df35fa7bbad795c9e49";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs:
    inputs.nixos-unified.lib.mkFlake {
      inherit inputs;
      root = ./.;
    };
}
