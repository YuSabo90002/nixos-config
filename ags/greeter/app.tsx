import { Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import style from "./style.scss"
import Greeter from "./widget/Greeter"

const settings = Gtk.Settings.get_default()!
settings.gtkApplicationPreferDarkTheme = true

app.start({
  css: style,
  instanceName: "greeter",
  main() {
    Greeter().present()
  },
})
