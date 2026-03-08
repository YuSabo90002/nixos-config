import { createState } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio?version=2.0"
import Greet from "gi://AstalGreet?version=0.1"

Gio._promisify(Greet, "login", "login_finish")

function formatTime(): string {
  const now = new Date()
  return now.toLocaleTimeString("ja-JP", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  })
}

function formatDate(): string {
  const now = new Date()
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"]
  const m = String(now.getMonth() + 1).padStart(2, "0")
  const d = String(now.getDate()).padStart(2, "0")
  const w = weekdays[now.getDay()]
  return `${m}/${d} (${w})`
}

export default function Greeter(gdkmonitor: Gdk.Monitor | null) {
  const time = createPoll(formatTime(), 1000, () => formatTime())
  const date = createPoll(formatDate(), 60000, () => formatDate())
  const [error, setError] = createState("")

  const username = "yuta"
  const sessionCmd = GLib.getenv("GREETER_SESSION_CMD") || ""

  let loggingIn = false

  async function handleLogin(password: string, entry: Gtk.Entry) {
    if (loggingIn) return
    loggingIn = true
    setError("")

    printerr(`[greeter] login attempt: user=${username}, cmd=${sessionCmd}`)

    try {
      await Greet.login(username, password, sessionCmd)
      printerr("[greeter] login success, exiting compositor")
      execAsync("hyprctl dispatch exit")
    } catch (e: any) {
      const msg = e?.message || "認証に失敗しました"
      printerr(`[greeter] login error: ${msg}`)
      setError(msg)
      entry.set_text("")
      entry.grab_focus()
      loggingIn = false
    }
  }

  return (
    <window
      name="Greeter"
      cssClasses={["Greeter"]}
      {...(gdkmonitor ? { gdkmonitor } : {})}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.EXCLUSIVE}
      layer={Astal.Layer.OVERLAY}
    >
      <box cssClasses={["greeter-overlay"]} orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.FILL} valign={Gtk.Align.FILL} hexpand vexpand>
        <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} hexpand vexpand>
          {/* 日付 */}
          <label
            cssClasses={["greeter-date"]}
            label={date}
          />
          {/* 時計 */}
          <label
            cssClasses={["greeter-time"]}
            label={time}
          />

          <box cssClasses={["greeter-spacer"]} />

          {/* ユーザー名 */}
          <label
            cssClasses={["greeter-username"]}
            label={username}
          />

          {/* パスワード入力欄 */}
          <entry
            cssClasses={["greeter-password"]}
            placeholderText=""
            visibility={false}
            halign={Gtk.Align.CENTER}
            onActivate={(self: Gtk.Entry) => {
              handleLogin(self.get_text(), self)
            }}
            onRealize={(self: Gtk.Entry) => {
              self.grab_focus()
            }}
          />

          {/* エラーメッセージ */}
          <label
            cssClasses={["greeter-error"]}
            label={error()}
            visible={error((e: string) => e !== "")}
          />
        </box>
      </box>
    </window>
  )
}
