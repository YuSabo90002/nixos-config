import { createState } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"

const [calendarOpen, setCalendarOpen] = createState(false)

export const calendarIsOpen = calendarOpen

export function toggleCalendar() {
  setCalendarOpen((prev) => !prev)
}

export default function CalendarPopup(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT, BOTTOM, LEFT } = Astal.WindowAnchor

  const win = (
    <window
      visible={calendarOpen}
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
    if (keyval === Gdk.KEY_Escape) setCalendarOpen(false)
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
    setCalendarOpen(false)
  })
  win.add_controller(bgClick)

  return win
}
