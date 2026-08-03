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
hl.window_rule({ name = "pear-desktop-ws",    match = { class = "com.github.th-ch.youtube-music" }, workspace = "10" })
hl.window_rule({ name = "pip-float",          match = { title = "^(Picture-in-Picture)$" },         float = true, pin = true })
hl.window_rule({ name = "swayimg-float",      match = { class = "^(swayimg)$" },                    float = true })

-------------------
---- 自動起動 ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("discord")
    hl.exec_cmd("pear-desktop")
end)
