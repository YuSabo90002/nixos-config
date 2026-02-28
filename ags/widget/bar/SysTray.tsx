import { createBinding, For } from "ags"
import Tray from "gi://AstalTray"

export default function SysTray() {
  const tray = Tray.get_default()
  const items = createBinding(tray, "items")

  return (
    <box cssClasses={["SysTray"]}>
      <For each={items}>
        {(item) => (
          <menubutton
            cssClasses={["tray-item"]}
            tooltipMarkup={createBinding(item, "tooltipMarkup")}
            $={(self: any) => {
              self.menuModel = item.menuModel
              self.insert_action_group("dbusmenu", item.actionGroup)
              item.connect("notify::action-group", () => {
                self.insert_action_group("dbusmenu", item.actionGroup)
              })
            }}
          >
            <image gicon={createBinding(item, "gicon")} />
          </menubutton>
        )}
      </For>
    </box>
  )
}
