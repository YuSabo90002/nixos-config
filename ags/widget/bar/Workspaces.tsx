import { createBinding } from "ags"
import Hyprland from "gi://AstalHyprland"

export default function Workspaces() {
  const hyprland = Hyprland.get_default()
  const workspaces = createBinding(hyprland, "workspaces")
  const focused = createBinding(hyprland, "focusedWorkspace")

  return (
    <box cssClasses={["Workspaces"]}>
      {workspaces((wss) => {
        const ids = Array.from({ length: 10 }, (_, i) => i + 1)
        const occupiedIds = new Set(
          wss
            .filter((ws) => !(ws.id >= -99 && ws.id <= -2))
            .map((ws) => ws.id),
        )

        return ids.map((id) => (
          <button
            cssClasses={focused((fw) => [
              ...(fw?.id === id ? ["focused"] : []),
              ...(occupiedIds.has(id) ? ["occupied"] : []),
            ])}
            onClicked={() => hyprland.dispatch("workspace", String(id))}
          />
        ))
      })}
    </box>
  )
}
