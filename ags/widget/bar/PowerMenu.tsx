import { Gtk } from "ags/gtk4"
import Hyprland from "gi://AstalHyprland"

function exec(cmd: string) {
  const proc = Gtk.init ? import("gi://Gio") : null
  import("gi://Gio").then((Gio) => {
    Gio.Subprocess.new(["bash", "-c", cmd], 0)
  })
}

export default function PowerMenu() {
  return (
    <button
      cssClasses={["PowerMenu"]}
      tooltipText="電源メニュー"
      $={(self: Gtk.Button) => {
        const items = [
          { icon: "system-shutdown-symbolic", label: "シャットダウン", cmd: "systemctl poweroff" },
          { icon: "system-reboot-symbolic", label: "再起動", cmd: "systemctl reboot" },
          { icon: "system-log-out-symbolic", label: "ログアウト", cmd: "hyprctl dispatch exit" },
          { icon: "weather-clear-night-symbolic", label: "スリープ", cmd: "systemctl suspend" },
        ]

        const box = new Gtk.Box({
          orientation: Gtk.Orientation.VERTICAL,
          spacing: 4,
        })

        for (const item of items) {
          const row = new Gtk.Button()
          row.add_css_class("power-item")
          row.set_tooltip_text(item.label)

          const rowBox = new Gtk.Box({
            orientation: Gtk.Orientation.HORIZONTAL,
            spacing: 8,
          })
          rowBox.append(new Gtk.Image({ iconName: item.icon }))
          rowBox.append(new Gtk.Label({ label: item.label }))
          row.set_child(rowBox)

          row.connect("clicked", () => {
            popover.popdown()
            import("gi://Gio").then((Gio) => {
              Gio.Subprocess.new(["bash", "-c", item.cmd], 0)
            })
          })

          box.append(row)
        }

        const popover = new Gtk.Popover()
        popover.add_css_class("PowerMenuPopup")
        popover.set_has_arrow(false)
        popover.set_child(box)
        popover.set_parent(self)

        self.connect("clicked", () => {
          if (popover.get_visible()) {
            popover.popdown()
          } else {
            popover.popup()
          }
        })
      }}
    >
      <image iconName="system-shutdown-symbolic" />
    </button>
  )
}
