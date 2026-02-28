import { createBinding, For } from "ags"
import Hyprland from "gi://AstalHyprland"

export default function Workspaces() {
  const hyprland = Hyprland.get_default()
  const workspaces = createBinding(hyprland, "workspaces")
  const focused = createBinding(hyprland, "focusedWorkspace")

  const ids = Array.from({ length: 10 }, (_, i) => i + 1)

  return (
    <box cssClasses={["Workspaces"]}>
      {ids.map((id) => (
        <button
          cssClasses={focused((fw) => [
            ...(fw?.id === id ? ["focused"] : []),
          ])}
          onClicked={() => hyprland.dispatch("workspace", String(id))}
        />
      ))}
    </box>
  )
}
