# Hyprland WM 設定 Lua 化 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ユーザーセッションの Hyprland 設定を hyprlang から Lua へ、動作等価で移行する。

**Architecture:** 本物の `hypr/hyprland.lua`（`hl.*` API）をリポジトリルートに直書きし、`modules/home/hyprland.nix` で `configType="lua"` + `extraConfig = builtins.readFile` により取り込む。greeter (`/etc/greetd/hyprland.conf`) と hyprlock/hypridle/hyprpaper は対象外。

**Tech Stack:** Nix (home-manager), Hyprland 0.55.2 Lua config API (`hl.config`/`hl.bind`/`hl.dsp.*`/`hl.window_rule`/`hl.monitor`/`hl.workspace_rule`/`hl.curve`/`hl.animation`/`hl.on`)

設計書: `docs/superpowers/specs/2026-05-31-hyprland-lua-config-design.md`

---

## 既知の事項（実装前に把握）

1. **`$mod CTRL L` の重複（既存設定のまま温存）**: 現行 hyprlang は同じ `$mod CTRL L` を
   `bind`（`loginctl lock-session`）と `binde`（`resizeactive 30 0`）の両方に割当てている
   （`modules/home/hyprland.nix:141` と `:203`）。動作等価方針のため Lua でも両方を登録する。
   挙動を変えたい場合は別途ユーザー判断。
2. **API は hyprlang と 1:1 ではない**: `hl.dsp.*` は再設計されており、本計画の各 Lua 表現は
   Hyprland 0.55.2 のソース（`LuaBindingsDispatchers.cpp` / `LuaBindingsConfigRules.cpp`）で
   検証済み。
3. **新規ファイルは `git add` 必須**: 未追跡だと flake のソースに含まれず
   `nix flake check` が `Could not resolve` で失敗する。各タスクで明示的に add する。

## File Structure

- Create: `hypr/hyprland.lua` — Lua 設定本体（モニタ/装飾/アニメ/bind/window_rule/autostart）。
- Create (任意): `hypr/.luarc.json` — 編集時 LSP 用（`hl` グローバル認識）。
- Modify: `modules/home/hyprland.nix:23-281` — WM 設定ブロックを slim 版に置換。
  hyprlock/hypridle/hyprpaper（283 行以降）は変更しない。

---

## Task 1: `hypr/hyprland.lua` を作成

**Files:**
- Create: `hypr/hyprland.lua`

- [ ] **Step 1: ファイルを作成（全内容を以下のとおり記述）**

```lua
-- ~/.config/hypr/hyprland.lua として配置される（home-manager が extraConfig 経由で取り込む）。
-- hyprlang からの移行。動作等価を目標とする。
-- モディファイアは " + " で連結、方向は left/right/up/down。

------------------
---- 変数 ----
------------------
local mod      = "SUPER"
local terminal = "alacritty"
local menu     = "ags request -i yuta-shell toggle-launcher"

------------------
---- モニター ----
------------------
hl.monitor({ output = "DP-1", mode = "2560x1440@60", position = "0x0",    scale = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "2560x0", scale = 1 })

-----------------------
---- LOOK & FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 3,
        col = {
            active_border   = { colors = { "rgba(A6E22Eee)", "rgba(66D9EFee)" }, angle = 45 },
            inactive_border = "rgba(75715Eaa)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
        rounding         = 10,
        active_opacity   = 1.0,
        inactive_opacity = 0.92,
        dim_inactive     = false,
        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
            offset       = "0 4",
        },
        blur = {
            enabled           = true,
            size              = 3,
            passes            = 2,
            new_optimizations = true,
            vibrancy          = 0.2,
            noise             = 0.02,
        },
    },

    animations = { enabled = true },

    dwindle = {
        preserve_split = true,
        force_split    = 2,
    },

    input = {
        kb_layout          = "us",
        follow_mouse       = 1,
        sensitivity        = 0,
        accel_profile      = "flat",
        numlock_by_default = false,
    },

    misc = {
        focus_on_activate        = true,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
        force_default_wallpaper  = 0,
    },
})

-- トラックボール
hl.device({ name = "kensington-expert-mouse", sensitivity = 0.8 })

-----------------------
---- アニメーション ----
-----------------------
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 4,  bezier = "easeOutQuint",   style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4,  bezier = "easeInOutCubic" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3,  bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 4,  bezier = "easeInOutCubic", style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 5,  bezier = "easeOutQuint" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "linear",         style = "loop" })

------------------------------
---- ワークスペース (モニタ別) ----
------------------------------
hl.workspace_rule({ workspace = "1",  monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "2",  monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "3",  monitor = "DP-1" })
hl.workspace_rule({ workspace = "4",  monitor = "DP-2" })
hl.workspace_rule({ workspace = "5",  monitor = "DP-1" })
hl.workspace_rule({ workspace = "6",  monitor = "DP-2" })
hl.workspace_rule({ workspace = "7",  monitor = "DP-1" })
hl.workspace_rule({ workspace = "8",  monitor = "DP-2" })
hl.workspace_rule({ workspace = "9",  monitor = "DP-1" })
hl.workspace_rule({ workspace = "10", monitor = "DP-2" })

---------------------
---- キーバインド ----
---------------------
-- 基本操作
hl.bind(mod .. " + Return",   hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + P",        hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + C",        hl.dsp.window.close())
hl.bind(mod .. " + M",        hl.dsp.exit())
hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("loginctl lock-session"))

-- レイアウト操作
hl.bind(mod .. " + V",             hl.dsp.layout("preselect d"))
hl.bind(mod .. " + B",             hl.dsp.layout("preselect r"))
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F",             hl.dsp.window.fullscreen())
hl.bind(mod .. " + D",             hl.dsp.window.pseudo())
hl.bind(mod .. " + SHIFT + F",     hl.dsp.window.pin())

-- スクリーンショット
hl.bind(mod .. " + S",         hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("grim - | wl-copy"))

-- ワークスペース切替 / ウィンドウ移動 (1-10)
for i = 1, 10 do
    local key = i % 10  -- 10 はキー 0 に対応
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- ワークスペース順送り/逆送り
hl.bind(mod .. " + Tab",         hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))

-- マウスホイールでワークスペース切替
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- フォーカス移動 (Vim風)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))

-- ウィンドウ入替 (Vim風)
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))

-- リサイズ (リピート可能) ※ mod+CTRL+L は lock とも重複（既存設定どおり温存）
hl.bind(mod .. " + CTRL + H", hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + L", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + K", hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + J", hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })

-- マウス操作
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------
---- ウィンドウルール ----
--------------------
hl.window_rule({ name = "pavucontrol-float",  match = { class = "pavucontrol" },                    float = true })
hl.window_rule({ name = "calculator-float",   match = { class = "org.gnome.Calculator" },           float = true })
hl.window_rule({ name = "dialog-open-file",   match = { title = "^(Open File)$" },                  float = true })
hl.window_rule({ name = "dialog-save-file",   match = { title = "^(Save File)$" },                  float = true })
hl.window_rule({ name = "dialog-open-folder", match = { title = "^(Open Folder)$" },                float = true })
hl.window_rule({ name = "steam-friends",      match = { title = "^(Friends List)$" },               float = true })
hl.window_rule({ name = "steam-settings",     match = { title = "^(Steam Settings)$" },             float = true })
hl.window_rule({ name = "steam-game",         match = { class = "^steam_app_" },                    fullscreen = true })
hl.window_rule({ name = "discord-ws",         match = { class = "discord" },                        workspace = "10" })
hl.window_rule({ name = "youtube-music-ws",   match = { class = "com.github.th_ch.youtube_music" }, workspace = "10" })
hl.window_rule({ name = "pip-float",          match = { title = "^(Picture-in-Picture)$" },         float = true, pin = true })

-------------------
---- 自動起動 ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("discord")
    hl.exec_cmd("pear-desktop")
end)
```

- [ ] **Step 2: git add（flake ソース純度のため必須）**

Run: `git add hypr/hyprland.lua`
Expected: エラーなし。`git status --short` に `A  hypr/hyprland.lua` が出る。

---

## Task 2: `hypr/.luarc.json` を作成（任意・編集時 LSP 用）

**Files:**
- Create: `hypr/.luarc.json`

スキップ可。lua-language-server で `hl` が未定義警告にならないようにする最小設定。
型補完まで欲しい場合は `workspace.library` に Hyprland パッケージの
`share/hypr/stubs` ディレクトリ（/nix/store パス）を追加するが、バージョン更新で
パスがドリフトするため本計画では globals 宣言のみとする。

- [ ] **Step 1: ファイルを作成**

```json
{
  "diagnostics.globals": ["hl"]
}
```

- [ ] **Step 2: git add**

Run: `git add hypr/.luarc.json`
Expected: エラーなし。

---

## Task 3: `modules/home/hyprland.nix` の WM ブロックを置換

**Files:**
- Modify: `modules/home/hyprland.nix:23-281`

- [ ] **Step 1: 現行の `wayland.windowManager.hyprland = { ... };` ブロック全体を置換**

現行 23〜281 行（`wayland.windowManager.hyprland = {` から、`extraConfig = ''...'';` を含む
閉じ `};` まで）を、以下に置き換える。`let ... in`（`wallpaperSrc`/`splitWallpapers`）と
283 行以降の `programs.hyprlock` / `services.hypridle` / `services.hyprpaper` は変更しない。

```nix
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua"; # 26.05+ の新デフォルト。設定本体は hypr/hyprland.lua に直書き
    package = pkgs.unstable.hyprland; # NixOSモジュール側と同じunstable版を使用
    systemd.enable = false; # UWSMが管理するため無効化
    settings = { }; # 構造化設定は使わない（中身は hyprland.lua へ）
    # 実 Lua ファイルを取り込む。extraConfig!="" により module が hyprland.lua を生成し
    # onChange=reloadConfig（hyprctl reload）が自動付与される。
    extraConfig = builtins.readFile ../../hypr/hyprland.lua;
  };
```

- [ ] **Step 2: 旧 settings/extraConfig が残っていないことを確認**

Run: `grep -nE 'windowrulev2|"\$mod"|bezier =|movefocus|swapwindow|killactive' modules/home/hyprland.nix`
Expected: hyprlock/hypridle/hyprpaper 由来でない WM 設定の残骸が無いこと（出力が空、
または hyprlock の `label`/`background` 等の対象外行のみ）。`bind`/`windowrule`/`monitor`
の旧 hyprlang 記述が消えていること。

---

## Task 4: 評価バリデーションと commit

- [ ] **Step 1: flake 評価チェック**

Run: `nix flake check 2>&1 | tail -30`
Expected: home-manager 構成が評価エラーなく通る。`Could not resolve` が出た場合は
`hypr/hyprland.lua` の `git add` 漏れ（Task 1 Step 2 / Task 2 Step 2 を確認）。

- [ ] **Step 2: 生成される hyprland.lua の中身を確認（任意・安心材料）**

Run: `nix build .#nixosConfigurations.Yuta-PC.config.system.build.toplevel 2>/dev/null; echo "build ok"`
Expected: ビルドが通る（`build ok`）。評価が通れば十分なので失敗時は Step 1 の出力を精査。

- [ ] **Step 3: commit**

```bash
git add hypr/hyprland.lua hypr/.luarc.json modules/home/hyprland.nix
git commit -m "$(cat <<'EOF'
home: hyprland WM 設定を hyprlang から lua へ移行

hypr/hyprland.lua に hl.* API で直書きし、configType=lua +
extraConfig=readFile で取り込む。動作等価（モニタ/装飾/アニメ/
bind/window_rule/autostart）。greeter と hyprlock/hypridle/
hyprpaper は対象外で hyprlang のまま。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
```
Expected: commit 成功。

---

## Task 5: 適用と実機検証

- [ ] **Step 1: 適用**

Run: `nix run .#activate`
Expected: home-manager 世代が切り替わる。`~/.config/hypr/hyprland.lua` が生成され（先頭に
`-- Generated by Home Manager`、続いて取り込んだ Lua）、`~/.config/hypr/.luarc.json` も存在。

Run: `head -5 ~/.config/hypr/hyprland.lua && test -f ~/.config/hypr/.luarc.json && echo luarc-ok`
Expected: ヘッダ行 + `luarc-ok`。

- [ ] **Step 2: 設定エラーが無いことを確認**

Run: `hyprctl reload && hyprctl configerrors`
Expected: `no errors` 相当（エラー列挙が無い）。エラーが出た場合は該当 `hl.*` 行を修正
（特に注意点: `shadow.offset` 文字列、`window_rule` のフィールド名 `float`/`fullscreen`/
`pin`/`workspace`、`match` の `class`/`title`）。

- [ ] **Step 3: 実機目視チェックリスト**

以下を手で確認（動作等価の確認）:
- モニタ配置: DP-1=2560x1440 左、DP-2=1920x1080 右（`hyprctl monitors` でも可）
- 端末起動 `SUPER+Return` / ランチャー `SUPER+P`
- ワークスペース 1-10 切替（`SUPER+1..0`）と移動（`SUPER+SHIFT+1..0`）、奇数=DP-1/偶数=DP-2
- Vim フォーカス `SUPER+H/J/K/L`、入替 `SUPER+SHIFT+H/J/K/L`
- リサイズ `SUPER+CTRL+H/J/K/L`（リピート）、ロック `SUPER+CTRL+L`（重複挙動を確認）
- フロート切替 `SUPER+SHIFT+Space`、全画面 `SUPER+F`、pin `SUPER+SHIFT+F`、pseudo `SUPER+D`
- preselect `SUPER+V`/`SUPER+B`
- スクショ `SUPER+S`（範囲）/`SUPER+SHIFT+S`（全体）
- マウス: `SUPER+左ドラッグ`移動 / `SUPER+右ドラッグ`リサイズ、ホイールでWS切替
- window_rule: pavucontrol/電卓のフロート、PiP の pin、steam_app_ 全画面、
  discord / youtube-music が WS10 へ
- autostart: discord / pear-desktop が起動
- アニメーション・枠グラデーション・ブラー・影が効く

- [ ] **Step 4: 対象外コンポーネントの回帰確認**

Run: `pidof hyprpaper hypridle >/dev/null && echo "paper/idle ok"`
Expected: `paper/idle ok`。壁紙が両モニタに出ている、`loginctl lock-session` で hyprlock が
出る、を目視確認（これらは hyprlang のまま据え置きのため変化しないはず）。

---

## Self-Review チェック結果

- **Spec coverage**: スコープ（WM のみ Lua 化、greeter/hyprlock/hypridle/hyprpaper 据え置き）=
  Task 3 + Task 5 Step 4。配置メカニズム（extraConfig=readFile）= Task 3。翻訳マッピング全項目
  = Task 1（monitor/config/curve/animation/device/workspace_rule/bind/window_rule/on を網羅）。
  検証計画 = Task 4・5。LSP = Task 2。
- **Placeholder scan**: コードは全て実値。要確認だった swap/preselect/layoutmsg/window_rule
  フィールド名は v0.55.2 ソースで確定済み（プレースホルダ無し）。
- **Type consistency**: dispatcher 名は登録テーブル（`hl.dsp.window.{close,float,fullscreen,
  pseudo,pin,move,swap,resize,drag}`、`hl.dsp.{focus,layout,exit,exec_cmd}`）と一致。
  window_rule フィールド（`float`/`fullscreen`/`pin`/`workspace`）は `WINDOW_RULE_EFFECT_DESCS`
  と一致。
- **未解決の設計上の判断（ユーザー周知事項）**: `$mod CTRL L` の lock/resize 重複は既存どおり温存。
