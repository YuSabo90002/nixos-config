import { Gdk, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Greeter from "./widget/Greeter"
import Background from "./widget/Background"
import GLib from "gi://GLib"

const settings = Gtk.Settings.get_default()!
settings.gtkApplicationPreferDarkTheme = true

function allGdkMonitors(): Gdk.Monitor[] {
  const monitors = Gdk.Display.get_default()!.get_monitors()
  const out: Gdk.Monitor[] = []
  for (let i = 0; i < monitors.get_n_items(); i++) {
    out.push(monitors.get_item(i) as Gdk.Monitor)
  }
  return out
}

app.start({
  css: style,
  instanceName: "greeter",
  main() {
    // 主モニターのコネクタ名は greetd 用 Hyprland の env で渡る
    // (modules/nixos/desktop.nix が my.monitors から生成)。
    const primaryName = GLib.getenv("PRIMARY_MONITOR")
    const all = allGdkMonitors()

    // 名前で引けなければ先頭のモニター、それも無ければ null (モニター指定なしで表示)。
    const primary =
      (primaryName ? all.find((m) => m.get_connector() === primaryName) : null) ?? all[0] ?? null

    // 主モニター: ログインフォーム付き Greeter
    Greeter(primary).present()

    // それ以外: 背景オーバーレイのみ
    for (const m of all) {
      if (m !== primary) Background(m).present()
    }
  },
})
