import { createState } from "ags"
import { execAsync } from "ags/process"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import Apps from "gi://AstalApps"

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

const [launcherOpen, setLauncherOpen] = createState(false)

export function toggleLauncher() {
  setLauncherOpen((prev) => !prev)
}

export default function Launcher(gdkmonitor: Gdk.Monitor) {
  const apps = new Apps.Apps()

  let entry: Gtk.Entry
  let listBox: Gtk.Box
  let results: Apps.Application[] = []

  function updateResults(query: string) {
    // 既存の子要素を削除
    let child = listBox.get_first_child()
    while (child) {
      const next = child.get_next_sibling()
      listBox.remove(child)
      child = next
    }

    results = query.length > 0
      ? apps.fuzzy_query(query).slice(0, 8)
      : apps.get_list().sort((a, b) => {
          // 使用頻度順（frequency降順）
          return (b.frequency ?? 0) - (a.frequency ?? 0)
        }).slice(0, 8)

    results.forEach((app, i) => {
      const btn = new Gtk.Button()
      btn.add_css_class("launcher-item")
      if (i === 0) btn.add_css_class("selected")
      btn.connect("clicked", () => launchApp(app))

      const hbox = new Gtk.Box({ spacing: 12 })

      const icon = new Gtk.Image({
        iconName: app.iconName || "application-x-executable",
        pixelSize: 32,
      })
      hbox.append(icon)

      const vbox = new Gtk.Box({
        orientation: Gtk.Orientation.VERTICAL,
        valign: Gtk.Align.CENTER,
      })

      const nameLabel = new Gtk.Label({
        label: app.name,
        halign: Gtk.Align.START,
      })
      nameLabel.add_css_class("launcher-item-name")
      vbox.append(nameLabel)

      if (app.description) {
        const descLabel = new Gtk.Label({
          label: app.description,
          halign: Gtk.Align.START,
          ellipsize: 3,
          maxWidthChars: 50,
        })
        descLabel.add_css_class("launcher-item-desc")
        vbox.append(descLabel)
      }

      hbox.append(vbox)
      btn.set_child(hbox)
      listBox.append(btn)
    })

    selectedIndex = results.length > 0 ? 0 : -1
  }

  let selectedIndex = -1

  function updateSelection() {
    let child = listBox.get_first_child()
    let i = 0
    while (child) {
      if (i === selectedIndex) {
        child.add_css_class("selected")
      } else {
        child.remove_css_class("selected")
      }
      child = child.get_next_sibling()
      i++
    }
  }

  function launchApp(app: Apps.Application) {
    // uwsm app 経由で systemd ユニットとして独立起動
    const desktopId = app.entry
    if (desktopId) {
      if (desktopId.includes(" ")) {
        // スペース入りDesktop Entry IDはuwsmが受け付けないためExecコマンドで渡す
        const cmd = app.executable.split(/\s+/)
        execAsync(["uwsm", "app", "--", ...cmd])
      } else {
        execAsync(["uwsm", "app", desktopId])
      }
    } else {
      app.launch()
    }
    setLauncherOpen(false)
  }

  function closeLauncher() {
    setLauncherOpen(false)
  }

  entry = new Gtk.Entry()
  entry.add_css_class("launcher-search")
  entry.hexpand = true
  entry.placeholderText = "アプリを検索..."

  entry.connect("changed", () => {
    updateResults(entry.get_text())
  })

  entry.connect("activate", () => {
    if (results.length > 0 && selectedIndex >= 0) {
      launchApp(results[selectedIndex])
    }
  })

  listBox = new Gtk.Box()
  listBox.add_css_class("launcher-list")
  listBox.orientation = Gtk.Orientation.VERTICAL
  listBox.spacing = 4

  const content = (
    <box
      orientation={Gtk.Orientation.VERTICAL}
      cssClasses={["launcher-content"]}
      spacing={8}
    >
      {entry}
      {listBox}
    </box>
  )

  const revealer = (
    <revealer
      transitionType={Gtk.RevealerTransitionType.CROSSFADE}
      transitionDuration={150}
      revealChild={false}
    >
      {content}
    </revealer>
  ) as Gtk.Revealer

  const win = (
    <window
      visible={false}
      name="Launcher"
      gdkmonitor={gdkmonitor}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      cssClasses={["Launcher"]}
    >
      <box halign={Gtk.Align.CENTER} valign={Gtk.Align.START}>
        {revealer}
      </box>
    </window>
  ) as Astal.Window

  // キーボード操作
  const keyCtrl = new Gtk.EventControllerKey()
  keyCtrl.connect("key-pressed", (_ctrl: any, keyval: number) => {
    if (keyval === Gdk.KEY_Escape) {
      closeLauncher()
      return true
    }
    if (keyval === Gdk.KEY_Down || (keyval === Gdk.KEY_n && _ctrl.get_current_event()?.get_modifier_state()! & Gdk.ModifierType.CONTROL_MASK)) {
      if (results.length > 0) {
        selectedIndex = (selectedIndex + 1) % results.length
        updateSelection()
      }
      return true
    }
    if (keyval === Gdk.KEY_Up || (keyval === Gdk.KEY_p && _ctrl.get_current_event()?.get_modifier_state()! & Gdk.ModifierType.CONTROL_MASK)) {
      if (results.length > 0) {
        selectedIndex = (selectedIndex - 1 + results.length) % results.length
        updateSelection()
      }
      return true
    }
    return false
  })
  win.add_controller(keyCtrl)

  // 背景クリックで閉じる
  const bgClick = new Gtk.GestureClick()
  bgClick.connect("released", (_gesture: any, _n: number, x: number, y: number) => {
    const child = win.get_child()
    if (child) {
      const alloc = child.get_allocation()
      if (x >= alloc.x && x <= alloc.x + alloc.width &&
          y >= alloc.y && y <= alloc.y + alloc.height) {
        return
      }
    }
    closeLauncher()
  })
  win.add_controller(bgClick)

  // 開閉制御
  launcherOpen.subscribe(() => {
    if (launcherOpen.peek()) {
      entry.set_text("")
      updateResults("")
      win.visible = true
      revealer.revealChild = true
      // フォーカスを入力欄に
      entry.grab_focus()
    } else {
      revealer.revealChild = false
    }
  })

  revealer.connect("notify::child-revealed", () => {
    if (!revealer.childRevealed) {
      win.visible = false
    }
  })

  return win
}
