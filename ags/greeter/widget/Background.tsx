import { Astal, Gdk, Gtk } from "ags/gtk4"

export default function Background(gdkmonitor: Gdk.Monitor) {
  return (
    <window
      name="GreeterBg"
      cssClasses={["Greeter"]}
      gdkmonitor={gdkmonitor}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.NONE}
      layer={Astal.Layer.OVERLAY}
    >
      <box cssClasses={["greeter-overlay"]} halign={Gtk.Align.FILL} valign={Gtk.Align.FILL} hexpand vexpand />
    </window>
  )
}
