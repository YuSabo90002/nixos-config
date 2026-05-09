import { createState } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createPoll, timeout } from "ags/time"
import { execAsync } from "ags/process"
import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio?version=2.0"
import Greet from "gi://AstalGreet?version=0.1"

// Greet.login() は auth_error 時に throw せず Error レスポンスを返したまま
// 後続の StartSession を呼び、結果として AGS が compositor を exit させてしまう。
// CreateSession → PostAuthMesssage → StartSession を自前で呼び、
// 各 Response の型を判定して正しく失敗をハンドリングする。
Gio._promisify(Greet.Request.prototype, "send", "send_finish")

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

  async function authenticate(password: string): Promise<void> {
    let resp: any = await new Greet.CreateSession({ username }).send()
    if (resp instanceof Greet.Error) {
      throw new Error(resp.description || "セッション作成失敗")
    }

    if (resp instanceof Greet.AuthMessage) {
      resp = await new Greet.PostAuthMesssage({ response: password }).send()
    }
    while (resp instanceof Greet.AuthMessage) {
      // INFO/ERROR 等の追加メッセージには空応答で進める
      resp = await new Greet.PostAuthMesssage({ response: "" }).send()
    }

    if (resp instanceof Greet.Error) {
      try { await new Greet.CancelSession().send() } catch (_) {}
      if (resp.errorType === Greet.ErrorType.AUTH_ERROR) {
        throw new Error("パスワードが違います")
      }
      throw new Error(resp.description || "認証エラー")
    }

    const startResp: any = await new Greet.StartSession({ cmd: [sessionCmd], env: [] }).send()
    if (startResp instanceof Greet.Error) {
      try { await new Greet.CancelSession().send() } catch (_) {}
      throw new Error(startResp.description || "セッション開始失敗")
    }
  }

  async function handleLogin(password: string, entry: Gtk.Entry, overlay: Gtk.Overlay) {
    if (loggingIn) return
    loggingIn = true
    setError("")
    overlay.remove_css_class("greeter-shake")

    printerr(`[greeter] login attempt: user=${username}, cmd=${sessionCmd}`)

    try {
      await authenticate(password)
      printerr("[greeter] login success, exiting compositor")
      execAsync("hyprctl dispatch exit")
    } catch (e: any) {
      const msg = e?.message || "認証に失敗しました"
      printerr(`[greeter] login error: ${msg}`)
      setError(msg)
      entry.set_text("")
      // シェイク + 赤フラッシュ
      overlay.add_css_class("greeter-shake")
      timeout(450, () => {
        overlay.remove_css_class("greeter-shake")
      })
      entry.grab_focus()
      loggingIn = false
    }
  }

  // パスワード入力欄（アニメーション付きドット表示）
  function createPasswordInput(): Gtk.Overlay {
    const overlay = new Gtk.Overlay()
    overlay.halign = Gtk.Align.CENTER

    const entry = new Gtk.Entry()
    entry.add_css_class("greeter-password")
    entry.add_css_class("greeter-password-hidden")
    entry.visibility = false
    entry.xalign = 0.5
    entry.halign = Gtk.Align.CENTER

    const dotsBox = new Gtk.Box()
    dotsBox.add_css_class("greeter-dots")
    dotsBox.halign = Gtk.Align.CENTER
    dotsBox.valign = Gtk.Align.CENTER
    dotsBox.canTarget = false
    dotsBox.spacing = 2

    overlay.set_child(entry)
    overlay.add_overlay(dotsBox)

    let currentLen = 0

    entry.connect("notify::text", () => {
      const newLen = entry.get_text().length

      if (newLen > currentLen) {
        // ドット追加（アニメーション付き）
        for (let i = currentLen; i < newLen; i++) {
          const dot = new Gtk.Label({ label: "●" })
          dot.add_css_class("greeter-dot")
          dotsBox.append(dot)
        }
      } else if (newLen < currentLen) {
        // ドット削除
        let toRemove = currentLen - newLen
        while (toRemove > 0) {
          const last = dotsBox.get_last_child()
          if (last) dotsBox.remove(last)
          toRemove--
        }
      }
      currentLen = newLen

      if (newLen > 0) {
        entry.remove_css_class("greeter-password-hidden")
        entry.add_css_class("greeter-password-visible")
      } else {
        entry.remove_css_class("greeter-password-visible")
        entry.add_css_class("greeter-password-hidden")
      }
    })

    entry.connect("activate", () => {
      handleLogin(entry.get_text(), entry, overlay)
    })

    entry.connect("realize", () => {
      entry.grab_focus()
    })

    return overlay
  }

  const passwordInput = createPasswordInput()

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

          {/* パスワード入力欄（アニメーション付きドット） */}
          {passwordInput}

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
