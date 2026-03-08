import { Gdk, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import StatusPanel from "./widget/StatusPanel"
import CalendarPopup from "./widget/CalendarPopup"
import NotificationPopups from "./widget/NotificationPopups"
import Launcher, { toggleLauncher } from "./widget/Launcher"
import Hyprland from "gi://AstalHyprland"

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
  instanceName: "yuta-shell",
  main() {
    const hyprland = Hyprland.get_default()

    const MAIN_MONITOR = "DP-1"

    // モニター名でバーを管理（Hyprland IDはGDKインデックスと一致しない場合がある）
    const bars = new Map<string, Gtk.Widget>()
    let panel: Gtk.Widget | null = null
    let calendar: Gtk.Widget | null = null

    const ensureBar = (monitor: { id: number; name: string }) => {
      if (!bars.has(monitor.name)) {
        const gdkMon = findGdkMonitor(monitor.name)
        if (gdkMon) {
          bars.set(monitor.name, Bar(gdkMon))
          if (monitor.name === MAIN_MONITOR) {
            if (!panel) panel = StatusPanel(gdkMon)
            if (!calendar) calendar = CalendarPopup(gdkMon)
          }
        }
      }
    }

    hyprland.connect("monitor-added", (_, monitor) => {
      ensureBar(monitor)
    })

    hyprland.connect("monitor-removed", (_, id) => {
      // monitor-removedはidで来るので、対応するモニターを探す
      for (const [name, widget] of bars) {
        // 残っているHyprlandモニターに含まれない名前のバーを削除
        const stillExists = hyprland.monitors.some((m: { name: string }) => m.name === name)
        if (!stillExists) {
          widget.close()
          bars.delete(name)
          if (name === MAIN_MONITOR) {
            if (panel) { panel.close(); panel = null }
            if (calendar) { calendar.close(); calendar = null }
          }
          break
        }
      }
    })

    // GDKモニターリストの変更を監視
    // sleep復帰時、Hyprlandのmonitor-addedよりGDKモニター追加が遅れることがあるため、
    // GDK側の変更でもバー作成を試みる
    const display = Gdk.Display.get_default()!
    const gdkMonitors = display.get_monitors()
    gdkMonitors.connect("items-changed", () => {
      for (const monitor of hyprland.monitors) {
        ensureBar(monitor)
      }
    })

    // リスナー接続後にモニター一覧をチェック
    // これにより、リスナー接続前に追加されたモニターも漏れなくバーが作成される
    for (const monitor of hyprland.monitors) {
      ensureBar(monitor)
    }

    NotificationPopups()

    // メインモニターにランチャーを表示
    const mainGdk = findGdkMonitor(MAIN_MONITOR)
    if (mainGdk) Launcher(mainGdk)
  },
  requestHandler(request: string, respond: (res: string) => void) {
    if (request.includes("toggle-launcher")) {
      toggleLauncher()
      respond("ok")
    } else {
      respond("unknown")
    }
  },
})
