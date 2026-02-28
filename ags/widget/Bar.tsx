import { Astal, Gtk } from "ags/gtk4"
import Workspaces from "./bar/Workspaces"
import Clock from "./bar/Clock"
import MediaPlayer from "./bar/MediaPlayer"
import SysTray from "./bar/SysTray"
import Volume from "./bar/Volume"
import NetworkIndicator from "./bar/NetworkIndicator"
import SystemMonitor from "./bar/SystemMonitor"
import PowerProfile from "./bar/PowerProfile"
import NotificationCenter from "./bar/NotificationCenter"

export default function Bar(monitor: number) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name={`bar-${monitor}`}
      monitor={monitor}
      anchor={TOP | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      cssClasses={["Bar"]}
    >
      <centerbox>
        <box hexpand halign={Gtk.Align.START}>
          <Workspaces />
        </box>

        <box>
          <MediaPlayer />
          <Clock />
        </box>

        <box hexpand halign={Gtk.Align.END}>
          <SysTray />
          <Volume />
          <NetworkIndicator />
          <SystemMonitor />
          <PowerProfile />
          <NotificationCenter />
        </box>
      </centerbox>
    </window>
  )
}
