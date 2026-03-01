# nixos-config

個人用 NixOS フレーク構成（Yuta-PC / x86_64-linux）

## 構成

| カテゴリ | 内容 |
|---------|------|
| WM | Hyprland (UWSM) |
| バー | AGS v3 (Astal) |
| ターミナル | Alacritty |
| シェル | Zsh + Starship |
| エディタ | NixVim |
| ランチャー | Wofi |
| 通知 | Dunst |
| 壁紙 | Hyprpaper（二画面スパン対応） |
| 日本語入力 | Fcitx5 + SKK |
| シークレット | agenix |
| ディスク | disko (btrfs) |

## モジュール構成

```
flake.nix
├── modules/
│   ├── nixos/          # システムレベル
│   │   ├── default.nix           # ユーザー, ブートローダー, SSH, Nix設定
│   │   ├── desktop.nix           # Hyprland, PipeWire, AMD GPU
│   │   ├── locale.nix            # ja_JP.UTF-8, fcitx5, フォント
│   │   ├── networking.nix        # systemd-networkd, iwd
│   │   ├── hardware-configuration.nix
│   │   └── disko-config.nix      # btrfs on NVMe
│   └── home/           # home-manager
│       ├── default.nix           # パッケージ, Git
│       ├── hyprland.nix          # キーバインド, ウィンドウルール, hyprpaper
│       ├── terminal.nix          # Alacritty
│       ├── shell.nix             # Zsh, Starship
│       ├── editors.nix           # NixVim
│       └── xdg.nix               # XDG設定
├── ags/                # AGS v3 バー (TypeScript)
├── secrets/            # agenix暗号化シークレット
└── configurations/     # ホスト定義
```

## 使い方

```bash
# ビルド & 適用
sudo nixos-rebuild switch --flake .

# ビルドのみ（テスト）
sudo nixos-rebuild build --flake .

# flake inputs 更新
nix flake update
```
