# nixos-config

個人用 NixOS フレーク構成。[nixos-unified](https://github.com/srid/nixos-unified) の autoWire で
ディレクトリ規約どおりに自動配線している。

## ホスト

| ホスト | 機体 | 備考 |
|--------|------|------|
| `Yuta-PC` | デスクトップ (AMD CPU / RX 9070 XT) | 2 画面、ComfyUI (ROCm)、HORI トラックホイール |
| `YuSabo-Laptop` | ThinkPad (Intel + NVIDIA Quadro T2000, Optimus) | 指紋認証、充電閾値、NVIDIA プライマリ |

どちらも x86_64-linux、nixpkgs は `nixos-26.05` (一部 `pkgs.unstable`)。

## 構成

| カテゴリ | 内容 |
|---------|------|
| WM | Hyprland (UWSM 経由、設定は `hypr/hyprland.lua` の Lua API) |
| シェル UI | AGS v3 (Astal) — バー・ランチャー・通知・スクリーンショットを 1 プロセスで |
| ログイン | greetd + AGS 製グリーター |
| ロック / アイドル | hyprlock + hypridle |
| 壁紙 | hyprpaper |
| ターミナル | Alacritty + tmux |
| シェル | Nushell + Starship |
| エディタ | NixVim / Zed / VS Code |
| ブラウザ | Zen Browser |
| 日本語入力 | Fcitx5 + SKK / 自作 IM の fcitx5-sekka |
| ネットワーク | systemd-networkd + iwd + resolved、Tailscale (SSH は tailnet 限定) |
| シークレット | agenix (SSH ホスト鍵で復号) |
| ディスク | disko (btrfs) |

## ディレクトリ構成

```
flake.nix
├── configurations/nixos/   # ホスト定義 (ディレクトリ = nixosConfigurations.<名前>)
│   ├── Yuta-PC/            #   default.nix / hardware.nix / disko.nix / comfyui.nix
│   └── YuSabo-Laptop/      #   default.nix / hardware.nix / disko.nix / nvidia.nix
├── modules/
│   ├── nixos/              # 全ホスト共通のシステム設定
│   │   ├── default.nix         # Nix 設定・GC, ブートローダー, SSH + mosh, podman, zram, kmscon
│   │   ├── desktop.nix         # Hyprland, greetd, PipeWire, polkit, Steam, Bluetooth
│   │   ├── locale.nix          # ja_JP.UTF-8, Asia/Tokyo, fcitx5, CJK フォント
│   │   ├── networking.nix      # systemd-networkd, iwd, resolved (mDNS)
│   │   ├── monitors.nix        # my.monitors (モニター定義の唯一の出どころ)
│   │   ├── printing.nix        # Brother DCP-L2540DW
│   │   ├── tailscale.nix       # Tailscale + Tailscale SSH
│   │   ├── laptop.nix          # ラップトップ用 (ホスト側から明示 import)
│   │   └── hori-wheel.nix      # HORI ホイールの HID 修正 (Yuta-PC のみ)
│   ├── home/               # home-manager
│   │   ├── default.nix         # パッケージ, AGS, Git ほか
│   │   ├── hyprland.nix        # hyprpaper, hyprlock, hypridle
│   │   ├── terminal.nix        # Alacritty
│   │   ├── shell.nix           # Nushell, Starship, direnv
│   │   ├── tmux.nix
│   │   ├── editors.nix         # NixVim, Zed, VS Code
│   │   └── xdg.nix             # 既定アプリ, desktop エントリ
│   └── flake-parts/        # flake-parts モジュール, devShell
├── ags/                    # AGS v3 ソース (widget/ = ユーザーシェル, greeter/ = ログイン画面)
├── hypr/hyprland.lua       # Hyprland 設定
├── overlays/               # pkgs.unstable, sekka 系, llm-agents, VS Code 拡張
├── packages/               # autoWire されるローカルパッケージ (.#<名前>)
├── pkgs/                   # autoWire に乗らないパッケージ (unfree / カーネルモジュール等)
└── secrets/                # agenix 暗号化シークレット
```

## 使い方

```bash
# 現在のホスト (hostname -s) をビルド & 適用
nix run .#activate

# ホストを指定して適用
nix run .#activate Yuta-PC

# flake inputs 更新 (全部 / 個別)
nix flake update
nix flake update <input名>

# 評価チェック
nix flake check
```

## メモ

- ホストを足すときは `configurations/nixos/<名前>/` を作るだけ。ただし agenix の復号に
  そのホストの SSH ホスト鍵が要るので、`secrets/secrets.nix` に公開鍵を足して `agenix -r` する。
- `ags/` に新しいファイルを足したら `git add` すること (未追跡だと flake のソースに入らない)。
- `libsekka` / `fcitx5-sekka` と greeter 用の `ags-greeter` / `astal-greeter` は固定しているので
  `nix flake update` では動かない。
