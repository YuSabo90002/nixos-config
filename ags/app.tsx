import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import NotificationPopups from "./widget/NotificationPopups"
import Hyprland from "gi://AstalHyprland"

app.start({
  css: style,
  instanceName: "yuta-shell",
  main() {
    const hyprland = Hyprland.get_default()
    for (const monitor of hyprland.monitors) {
      Bar(monitor.id)
    }
    NotificationPopups()
  },
})
