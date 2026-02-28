import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import Hyprland from "gi://AstalHyprland"

export default function Workspaces() {
  const hyprland = Hyprland.get_default()
  const workspaces = createBinding(hyprland, "workspaces")
  const focused = createBinding(hyprland, "focusedWorkspace")

  const ids = Array.from({ length: 10 }, (_, i) => i + 1)

  return (
    <box cssClasses={["Workspaces"]} valign={Gtk.Align.CENTER}>
      {ids.map((id) => (
        <button
          cssClasses={focused((fw) => {
            const classes: string[] = []
            if (fw?.id === id) classes.push("focused")
            if (hyprland.workspaces.some((ws) => ws.id === id && ws.clients.length > 0))
              classes.push("occupied")
            return classes
          })}
          onClicked={() => hyprland.dispatch("workspace", String(id))}
        />
      ))}
    </box>
  )
}
