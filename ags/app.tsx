import { Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import NotificationPopups from "./widget/NotificationPopups"
import Hyprland from "gi://AstalHyprland"

const settings = Gtk.Settings.get_default()!
settings.gtkApplicationPreferDarkTheme = true

app.start({
  css: style,
  instanceName: "yuta-shell",
  main() {
    const hyprland = Hyprland.get_default()

    const bars = new Map<number, Gtk.Widget>()

    for (const monitor of hyprland.monitors) {
      bars.set(monitor.id, Bar(monitor.id))
    }

    hyprland.connect("monitor-added", (_, monitor) => {
      if (!bars.has(monitor.id)) {
        bars.set(monitor.id, Bar(monitor.id))
      }
    })

    hyprland.connect("monitor-removed", (_, id) => {
      bars.get(id)?.close()
      bars.delete(id)
    })

    NotificationPopups()
  },
})
