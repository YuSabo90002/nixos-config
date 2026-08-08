# このホストの物理モニター構成を 1 箇所で定義する。
#
# 以前は DP-1 / DP-2 が greeter・hyprland.lua・hyprpaper・hyprlock・AGS バーの
# 5 箇所にバラバラに直書きされており、2 台目 (ラップトップ = 内蔵パネル 1 枚) を
# 足すと全部書き換える必要があった。ここを唯一の出どころにして、各所は
# config.my.monitors / osConfig.my.monitors から導出する。
{ config, lib, ... }:
{
  options.my.monitors = lib.mkOption {
    description = ''
      このホストに繋がるモニター。定義順が並び順ではなく、position で明示する。
      ちょうど 1 つを primary = true にすること (greeter・ロック画面・AGS バーの
      主画面判定に使う)。
    '';
    type = lib.types.listOf (lib.types.submodule {
      options = {
        output = lib.mkOption {
          type = lib.types.str;
          description = "コネクタ名。`ls /sys/class/drm` の cardN-<名前> の部分 (例: DP-1, eDP-1)。";
        };
        width = lib.mkOption { type = lib.types.ints.positive; };
        height = lib.mkOption { type = lib.types.ints.positive; };
        refresh = lib.mkOption {
          type = lib.types.ints.positive;
          default = 60;
        };
        x = lib.mkOption {
          type = lib.types.int;
          default = 0;
          description = "レイアウト上の左端の座標。";
        };
        y = lib.mkOption {
          type = lib.types.int;
          default = 0;
          description = "レイアウト上の上端の座標。";
        };
        scale = lib.mkOption {
          type = lib.types.either lib.types.int lib.types.float;
          default = 1;
        };
        primary = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        workspaces = lib.mkOption {
          type = lib.types.listOf lib.types.ints.positive;
          default = [ ];
          description = ''
            このモニターに固定するワークスペース番号。先頭がこのモニターの
            既定ワークスペース (hyprland の workspace_rule の default = true) になる。
          '';
        };
      };
    });
  };

  # primary がちょうど 1 枚であることを保証する。ここが 0 枚だと壁紙サイズや
  # ロック画面の入力欄が無言で壊れる (エラーにならず画面だけおかしくなる) ので
  # 評価時に落とす。
  config.assertions =
    let
      primaries = lib.filter (m: m.primary) config.my.monitors;
    in
    [
      {
        assertion = config.my.monitors == [ ] || lib.length primaries == 1;
        message =
          "my.monitors: primary = true はちょうど 1 つ必要 (現在 ${toString (lib.length primaries)} 個)";
      }
    ];
}
