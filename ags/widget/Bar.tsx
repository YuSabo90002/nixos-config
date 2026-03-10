import { Astal, Gdk, Gtk } from "ags/gtk4"
import Workspaces from "./bar/Workspaces"
import Clock from "./bar/Clock"
import SysTray from "./bar/SysTray"
import SystemMonitor from "./bar/SystemMonitor"
import { toggleStatusPanel, statusPanelOpen } from "./StatusPanel"

function PanelToggleButton() {
  return (
    <button
      cssClasses={statusPanelOpen((open) => open ? ["PanelToggle", "active"] : ["PanelToggle"])}
      onClicked={toggleStatusPanel}
      tooltipText="ステータスパネル"
    >
      <image iconName={statusPanelOpen((open) =>
        open ? "pan-up-symbolic" : "pan-down-symbolic"
      )} />
    </button>
  )
}

function BarContent(isMain: boolean, monitorName: string) {
  const overlay = new Gtk.Overlay()

  const base = (
    <box>
      <box hexpand halign={Gtk.Align.START}>
        <Workspaces />
      </box>
      <box hexpand halign={Gtk.Align.END}>
        <SystemMonitor />
        <SysTray />
        {isMain && <PanelToggleButton />}
      </box>
    </box>
  ) as Gtk.Widget

  const clock = (
    <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
      <Clock monitorName={monitorName} />
    </box>
  ) as Gtk.Widget

  overlay.set_child(base)
  overlay.add_overlay(clock)

  return overlay
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  const isMain = gdkmonitor.get_connector() === "DP-1"

  const win = (
    <window
      visible
      name={`bar-${gdkmonitor.get_connector()}`}
      gdkmonitor={gdkmonitor}
      anchor={TOP | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      cssClasses={["Bar"]}
    />
  ) as Astal.Window

  win.set_child(BarContent(isMain, gdkmonitor.get_connector()!))

  return win
}
