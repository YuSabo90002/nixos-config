import { Gdk, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Greeter from "./widget/Greeter"
import Background from "./widget/Background"

const settings = Gtk.Settings.get_default()!
settings.gtkApplicationPreferDarkTheme = true

// Hyprlandのモニター名からGdkMonitorを探す
function findGdkMonitor(name: string): Gdk.Monitor | null {
  const display = Gdk.Display.get_default()!
  const monitors = display.get_monitors()
  for (let i = 0; i < monitors.get_n_items(); i++) {
    const gdkMon = monitors.get_item(i) as Gdk.Monitor
    if (gdkMon.get_connector() === name) {
      return gdkMon
    }
  }
  return null
}

app.start({
  css: style,
  instanceName: "greeter",
  main() {
    const dp1 = findGdkMonitor("DP-1")
    const dp2 = findGdkMonitor("DP-2")

    // DP-1: ログインフォーム付きGreeter
    if (dp1) {
      Greeter(dp1).present()
    } else {
      // フォールバック: モニターが見つからない場合はデフォルトで表示
      Greeter(null).present()
    }

    // DP-2: 背景オーバーレイのみ
    if (dp2) {
      Background(dp2).present()
    }

  },
})
