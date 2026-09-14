import { execAsync } from "ags/process"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import Hyprland from "gi://AstalHyprland"
import GdkPixbuf from "gi://GdkPixbuf"
import Gio from "gi://Gio"
import GLib from "gi://GLib"

const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

// プレビューの最大サイズ。これより小さい画像は等倍のまま出す
const PREVIEW_WIDTH = 640
const PREVIEW_HEIGHT = 360

export type ScreenshotMode = "region" | "output"

// 撮影から選択が終わるまでは次の撮影を受け付けない (選択ポップアップが写り込むため)
let busy = false

// 撮影してから、コピーするか保存するかをポップアップで選ばせる。
// ポップアップが写らないように、撮影は先に一時ファイルへ済ませておく。
export async function takeScreenshot(
  mode: ScreenshotMode,
  findMonitor: (name: string) => Gdk.Monitor | null,
) {
  if (busy) return
  busy = true

  const hyprland = Hyprland.get_default()
  const monitorName = hyprland.focusedMonitor.name
  const file = GLib.build_filenamev([
    GLib.get_user_runtime_dir(),
    `screenshot-${GLib.get_real_time()}.png`,
  ])

  let grimArgs: string[]
  if (mode === "region") {
    try {
      // Esc で範囲選択をやめると slurp は非 0 で終わる
      const geometry = (await execAsync(["slurp"])).trim()
      grimArgs = ["-g", geometry]
    } catch {
      busy = false
      return
    }
  } else {
    grimArgs = ["-o", monitorName]
  }

  try {
    await execAsync(["grim", ...grimArgs, file])
  } catch (e) {
    console.error(e)
    busy = false
    return
  }

  Chooser(file, findMonitor(monitorName))
}

async function copyToClipboard(file: string) {
  // wl-copy は常駐する子プロセスが stdout を握ったままになり execAsync が返らないので捨てる
  await execAsync(["sh", "-c", 'wl-copy --type image/png < "$1" >/dev/null 2>&1', "sh", file])
  GLib.unlink(file)
}

function saveToPictures(file: string): string {
  const pictures = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_PICTURES)
    ?? GLib.build_filenamev([GLib.get_home_dir(), "Pictures"])
  const dir = GLib.build_filenamev([pictures, "Screenshots"])
  GLib.mkdir_with_parents(dir, 0o755)

  const stamp = GLib.DateTime.new_now_local().format("%Y-%m-%d_%H-%M-%S")
  let dest = GLib.build_filenamev([dir, `Screenshot_${stamp}.png`])
  // 同じ秒に続けて撮ったときに上書きしないよう連番を付ける
  for (let i = 1; GLib.file_test(dest, GLib.FileTest.EXISTS); i++) {
    dest = GLib.build_filenamev([dir, `Screenshot_${stamp}_${i}.png`])
  }

  Gio.File.new_for_path(file).move(Gio.File.new_for_path(dest), Gio.FileCopyFlags.NONE, null, null)
  return dest
}

function preview(file: string): Gtk.Picture {
  // Gtk.Picture は画像の実寸を自然サイズとして要求するので、縮小した画像を渡す
  const [, width, height] = GdkPixbuf.Pixbuf.get_file_info(file)
  const scale = Math.min(1, PREVIEW_WIDTH / width, PREVIEW_HEIGHT / height)
  const pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
    file,
    Math.max(1, Math.round(width * scale)),
    Math.max(1, Math.round(height * scale)),
    true,
  )
  const picture = Gtk.Picture.new_for_paintable(Gdk.Texture.new_for_pixbuf(pixbuf))
  picture.add_css_class("screenshot-preview")
  return picture
}

function Chooser(file: string, gdkmonitor: Gdk.Monitor | null) {
  let finished = false

  async function finish(action: "copy" | "save" | "cancel") {
    if (finished) return
    finished = true
    win.destroy()

    try {
      if (action === "copy") await copyToClipboard(file)
      else if (action === "save") saveToPictures(file)
      else GLib.unlink(file)
    } catch (e) {
      // 保存に失敗しても撮った画像は消さずに一時ファイルとして残す
      console.error(`スクリーンショットの処理に失敗 (${file}):`, e)
    } finally {
      busy = false
    }
  }

  const win = (
    <window
      name="Screenshot"
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.EXCLUSIVE}
      cssClasses={["Screenshot"]}
    >
      <box
        orientation={Gtk.Orientation.VERTICAL}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        spacing={12}
        cssClasses={["screenshot-content"]}
      >
        {preview(file)}
        <box spacing={8} halign={Gtk.Align.CENTER} homogeneous>
          <button
            cssClasses={["screenshot-btn", "primary"]}
            label="コピー (C)"
            onClicked={() => finish("copy")}
          />
          <button
            cssClasses={["screenshot-btn"]}
            label="保存 (S)"
            onClicked={() => finish("save")}
          />
          <button
            cssClasses={["screenshot-btn"]}
            label="キャンセル (Esc)"
            onClicked={() => finish("cancel")}
          />
        </box>
      </box>
    </window>
  ) as Astal.Window

  // モニターが引けなければ未指定のまま (コンポジタがフォーカス中の出力に出す)
  if (gdkmonitor) win.gdkmonitor = gdkmonitor

  // Enter はフォーカス中のボタン (初期状態ではコピー) が拾う
  const keyCtrl = new Gtk.EventControllerKey()
  keyCtrl.connect("key-pressed", (_ctrl: Gtk.EventControllerKey, keyval: number) => {
    switch (keyval) {
      case Gdk.KEY_c:
        finish("copy")
        return true
      case Gdk.KEY_s:
        finish("save")
        return true
      case Gdk.KEY_Escape:
        finish("cancel")
        return true
    }
    return false
  })
  win.add_controller(keyCtrl)

  win.present()
}
