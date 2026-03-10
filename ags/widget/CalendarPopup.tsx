import { createState } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"

// 開いているモニター名を保持（null = 閉じている）
const [openMonitor, setOpenMonitor] = createState<string | null>(null)

export const calendarIsOpen = openMonitor

export function toggleCalendar(monitorName: string) {
  setOpenMonitor((prev) => prev === null ? monitorName : null)
}

export default function CalendarPopup(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT, BOTTOM, LEFT } = Astal.WindowAnchor

  const win = (
    <window
      visible={openMonitor((m) => m === gdkmonitor.get_connector())}
      name={`calendar-popup-${gdkmonitor.get_connector()}`}
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT | BOTTOM | LEFT}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.TOP}
      keymode={Astal.Keymode.ON_DEMAND}
      cssClasses={["CalendarPopup"]}
    >
      <box
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.START}
        cssClasses={["calendar-content"]}
      >
        <Gtk.Calendar cssClasses={["calendar"]} />
      </box>
    </window>
  ) as Astal.Window

  // Escapeキーで閉じる
  const keyCtrl = new Gtk.EventControllerKey()
  keyCtrl.connect("key-pressed", (_ctrl: any, keyval: number) => {
    if (keyval === Gdk.KEY_Escape) setOpenMonitor(null)
  })
  win.add_controller(keyCtrl)

  // カレンダー外クリックで閉じる（カレンダー内は無視）
  const bgClick = new Gtk.GestureClick()
  bgClick.connect("released", (_gesture: any, _n: number, x: number, y: number) => {
    const content = win.get_child()
    if (content) {
      const alloc = content.get_allocation()
      if (x >= alloc.x && x <= alloc.x + alloc.width &&
          y >= alloc.y && y <= alloc.y + alloc.height) {
        return
      }
    }
    setOpenMonitor(null)
  })
  win.add_controller(bgClick)

  return win
}
