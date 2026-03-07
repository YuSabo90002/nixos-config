import { createState, createBinding, With, type Accessor } from "ags"
import { Astal, Gdk, Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import { exec, execAsync } from "ags/process"
import Wp from "gi://AstalWp"
import Mpris from "gi://AstalMpris"
import Notifd from "gi://AstalNotifd"

const [panelOpen, setPanelOpen] = createState(false)

export const statusPanelOpen = panelOpen

export function toggleStatusPanel() {
  setPanelOpen((prev) => !prev)
}

// --- 音量セクション ---
function VolumeSection() {
  const wp = Wp.get_default()!
  const speaker = wp.audio.defaultSpeaker!

  const icon = createBinding(speaker, "volumeIcon")
  const muted = createBinding(speaker, "mute")

  return (
    <box cssClasses={["panel-section", "volume-section"]} spacing={8}>
      <button
        cssClasses={muted((m) => m ? ["panel-icon-btn", "muted"] : ["panel-icon-btn"])}
        onClicked={() => { speaker.mute = !speaker.mute }}
      >
        <image iconName={icon} />
      </button>
      <slider
        hexpand
        cssClasses={["panel-slider"]}
        value={createBinding(speaker, "volume")}
        onChangeValue={(self) => { speaker.volume = self.get_value() }}
      />
      <label
        cssClasses={["panel-value"]}
        label={createBinding(speaker, "volume")((v) => `${Math.round(v * 100)}%`)}
      />
    </box>
  )
}

// --- ネットワークセクション ---
function getNetworkState() {
  try {
    const ethState = readFile("/sys/class/net/enp8s0/operstate").trim()
    if (ethState === "up") {
      return { icon: "network-wired-symbolic", label: "有線接続", connected: true }
    }
    const wlanState = readFile("/sys/class/net/wlan0/operstate").trim()
    if (wlanState === "up") {
      try {
        const out = exec(["networkctl", "status", "wlan0"])
        const apLine = out.split("\n").find((l) => l.includes("Wi-Fi access point"))
        const match = apLine?.match(/Wi-Fi access point:\s*(.+?)\s*\(/)
        const ssid = match?.[1] || "WiFi"
        return { icon: "network-wireless-symbolic", label: ssid, connected: true }
      } catch {
        return { icon: "network-wireless-symbolic", label: "WiFi", connected: true }
      }
    }
    return { icon: "network-disconnected-symbolic", label: "未接続", connected: false }
  } catch {
    return { icon: "network-disconnected-symbolic", label: "不明", connected: false }
  }
}

const netPoll = createPoll(JSON.stringify(getNetworkState()), 5000, () => JSON.stringify(getNetworkState()))

function NetworkSection() {
  return (
    <box cssClasses={["panel-section", "network-section"]} spacing={8}>
      <image iconName={netPoll((v) => {
        try { return JSON.parse(v).icon } catch { return "network-disconnected-symbolic" }
      })} />
      <label hexpand halign={Gtk.Align.START} label={netPoll((v) => {
        try { return JSON.parse(v).label } catch { return "不明" }
      })} />
      <label cssClasses={["panel-status"]} label={netPoll((v) => {
        try { return JSON.parse(v).connected ? "接続中" : "切断" } catch { return "" }
      })} />
    </box>
  )
}

// --- CPU/メモリセクション ---
let prevIdle = 0
let prevTotal = 0

function getCpuUsage(): number {
  try {
    const stat = readFile("/proc/stat")
    const line = stat.split("\n")[0]
    const cols = line.split(/\s+/).slice(1).map(Number)
    const idle = cols[3]
    const total = cols.reduce((a, b) => a + b, 0)
    const diffIdle = idle - prevIdle
    const diffTotal = total - prevTotal
    prevIdle = idle
    prevTotal = total
    if (diffTotal === 0) return 0
    return Math.round(((diffTotal - diffIdle) / diffTotal) * 100)
  } catch {
    return 0
  }
}

function getMemUsage(): { percent: number; used: string; total: string } {
  try {
    const meminfo = readFile("/proc/meminfo")
    const lines = meminfo.split("\n")
    const total = parseInt(lines[0].split(/\s+/)[1])
    const available = parseInt(lines[2].split(/\s+/)[1])
    const used = total - available
    const percent = Math.round((used / total) * 100)
    const toGiB = (kb: number) => (kb / 1048576).toFixed(1)
    return { percent, used: `${toGiB(used)} GiB`, total: `${toGiB(total)} GiB` }
  } catch {
    return { percent: 0, used: "0 GiB", total: "0 GiB" }
  }
}

const sysPoll = createPoll("", 2000, () => {
  const cpu = getCpuUsage()
  const mem = getMemUsage()
  return JSON.stringify({ cpu, mem })
})

function colorClass(value: number): string {
  if (value >= 80) return "critical"
  if (value >= 50) return "warning"
  return "normal"
}

function SystemSection() {
  return (
    <box cssClasses={["panel-section", "system-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      {/* CPU */}
      <box spacing={8}>
        <label cssClasses={["panel-section-icon", "cpu-color"]} label="" />
        <label halign={Gtk.Align.START} label="CPU" />
        <label hexpand halign={Gtk.Align.END} cssClasses={sysPoll((v) => {
          try { return ["panel-value", colorClass(JSON.parse(v).cpu)] } catch { return ["panel-value"] }
        })} label={sysPoll((v) => {
          try { return `${JSON.parse(v).cpu}%` } catch { return "0%" }
        })} />
      </box>
      <levelbar
        cssClasses={["panel-level", "cpu-level"]}
        value={sysPoll((v) => {
          try { return JSON.parse(v).cpu / 100 } catch { return 0 }
        })}
      />
      {/* メモリ */}
      <box spacing={8}>
        <label cssClasses={["panel-section-icon", "mem-color"]} label="󰍛" />
        <label halign={Gtk.Align.START} label="メモリ" />
        <label hexpand halign={Gtk.Align.END} cssClasses={sysPoll((v) => {
          try { return ["panel-value", colorClass(JSON.parse(v).mem.percent)] } catch { return ["panel-value"] }
        })} label={sysPoll((v) => {
          try {
            const { mem } = JSON.parse(v)
            return `${mem.used} / ${mem.total}`
          } catch { return "" }
        })} />
      </box>
      <levelbar
        cssClasses={["panel-level", "mem-level"]}
        value={sysPoll((v) => {
          try { return JSON.parse(v).mem.percent / 100 } catch { return 0 }
        })}
      />
    </box>
  )
}

// --- 温度セクション ---
type TempSensor = { path: string; label: string; name: string }

function findTempSensors(): TempSensor[] {
  const sensors: TempSensor[] = []
  const base = "/sys/class/hwmon"
  for (let i = 0; i < 20; i++) {
    let hwName: string
    try { hwName = readFile(`${base}/hwmon${i}/name`).trim() } catch { continue }

    for (let t = 1; t <= 5; t++) {
      const path = `${base}/hwmon${i}/temp${t}_input`
      try { readFile(path) } catch { continue }

      let label: string
      try { label = readFile(`${base}/hwmon${i}/temp${t}_label`).trim() } catch { label = "" }

      switch (hwName) {
        case "k10temp":
          sensors.push({ path, label: "CPU (Tctl)", name: hwName })
          break
        case "amdgpu":
          if (label === "edge") sensors.push({ path, label: `GPU (${label})`, name: hwName })
          else if (label === "junction") sensors.push({ path, label: `GPU (${label})`, name: hwName })
          else if (label === "mem") sensors.push({ path, label: `GPU VRAM`, name: hwName })
          break
        case "nvme": {
          if (label === "Composite") {
            const devIdx = sensors.filter((s) => s.name === "nvme").length
            sensors.push({ path, label: `NVMe ${devIdx}`, name: hwName })
          }
          break
        }
      }
    }
  }
  return sensors
}

const tempSensors = findTempSensors()

function readTemp(path: string): number {
  try { return Math.round(parseInt(readFile(path).trim()) / 1000) } catch { return 0 }
}

function tempColorClass(value: number): string {
  if (value >= 85) return "critical"
  if (value >= 65) return "warning"
  return "normal"
}

const tempPoll = createPoll("[]", 2000, () => {
  return JSON.stringify(tempSensors.map((s) => ({
    label: s.label,
    temp: readTemp(s.path),
  })))
})

function TemperatureSection() {
  return (
    <box cssClasses={["panel-section", "temp-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={6}>
      <box spacing={8}>
        <label cssClasses={["panel-section-icon", "temp-color"]} label="" />
        <label halign={Gtk.Align.START} label="温度" />
      </box>
      {tempSensors.map((sensor, idx) => (
        <box spacing={8}>
          <label halign={Gtk.Align.START} cssClasses={["temp-label"]} label={sensor.label} />
          <label hexpand halign={Gtk.Align.END} cssClasses={tempPoll((v) => {
            try { return ["panel-value", tempColorClass(JSON.parse(v)[idx].temp)] } catch { return ["panel-value"] }
          })} label={tempPoll((v) => {
            try { return `${JSON.parse(v)[idx].temp} °C` } catch { return "0 °C" }
          })} />
        </box>
      ))}
    </box>
  )
}

// --- メディアプレーヤーセクション ---
function MediaSection() {
  const mpris = Mpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <box cssClasses={["panel-section", "media-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <With value={players}>
        {(ps) => {
          const player = ps[0]
          if (!player) {
            return (
              <box spacing={8}>
                <label cssClasses={["panel-section-icon", "media-color"]} label="󰎇" />
                <label cssClasses={["panel-status"]} label="再生中の音楽なし" />
              </box>
            )
          }

          const title = createBinding(player, "title")
          const artist = createBinding(player, "artist")
          const coverArt = createBinding(player, "coverArt")
          const playbackStatus = createBinding(player, "playbackStatus")
          const canGoNext = createBinding(player, "canGoNext")
          const canGoPrevious = createBinding(player, "canGoPrevious")
          const canControl = createBinding(player, "canControl")

          return (
            <box spacing={10}>
              {/* アルバムアート */}
              <box
                cssClasses={["media-cover-box"]}
                widthRequest={80}
                heightRequest={80}
              >
                <image
                  cssClasses={["media-cover"]}
                  file={coverArt((c) => c || "")}
                  pixelSize={80}
                />
              </box>
              {/* 曲情報 + コントロール */}
              <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={2} valign={Gtk.Align.CENTER}>
                <label
                  cssClasses={["media-title"]}
                  label={title((t) => t || "不明な曲")}
                  halign={Gtk.Align.START}
                  ellipsize={3}
                  maxWidthChars={24}
                />
                <label
                  cssClasses={["media-artist"]}
                  label={artist((a) => a || "")}
                  halign={Gtk.Align.START}
                  ellipsize={3}
                  maxWidthChars={24}
                />
                <box spacing={4} halign={Gtk.Align.START}>
                  <button
                    cssClasses={["media-ctrl-btn"]}
                    sensitive={canGoPrevious}
                    onClicked={() => player.previous()}
                  >
                    <image iconName="media-skip-backward-symbolic" />
                  </button>
                  <button
                    cssClasses={["media-ctrl-btn", "media-play-btn"]}
                    sensitive={canControl}
                    onClicked={() => player.play_pause()}
                  >
                    <image iconName={playbackStatus((s) =>
                      s === Mpris.PlaybackStatus.PLAYING
                        ? "media-playback-pause-symbolic"
                        : "media-playback-start-symbolic"
                    )} />
                  </button>
                  <button
                    cssClasses={["media-ctrl-btn"]}
                    sensitive={canGoNext}
                    onClicked={() => player.next()}
                  >
                    <image iconName="media-skip-forward-symbolic" />
                  </button>
                </box>
              </box>
            </box>
          )
        }}
      </With>
    </box>
  )
}

// --- クイック設定ボタン ---
function QuickToggles() {
  const notifd = Notifd.get_default()
  const dnd = createBinding(notifd, "dontDisturb")

  return (
    <box cssClasses={["panel-section", "quick-toggles"]} spacing={8} homogeneous>
      <button
        cssClasses={dnd((d) => d ? ["toggle-btn", "active"] : ["toggle-btn"])}
        onClicked={() => { notifd.dontDisturb = !notifd.dontDisturb }}
        tooltipText={dnd((d) => d ? "通知: オフ" : "通知: オン")}
      >
        <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
          <image iconName={dnd((d) =>
            d ? "notifications-disabled-symbolic" : "preferences-system-notifications-symbolic"
          )} />
          <label label="通知" />
        </box>
      </button>
    </box>
  )
}

// --- 電源ボタン ---
function PowerButtons() {
  const items = [
    { icon: "system-lock-screen-symbolic", label: "ロック", cmd: "loginctl lock-session" },
    { icon: "weather-clear-night-symbolic", label: "スリープ", cmd: "systemctl suspend" },
    { icon: "system-log-out-symbolic", label: "ログアウト", cmd: "uwsm stop" },
    { icon: "system-reboot-symbolic", label: "再起動", cmd: "systemctl reboot" },
    { icon: "system-shutdown-symbolic", label: "シャットダウン", cmd: "systemctl poweroff" },
  ]

  return (
    <box cssClasses={["panel-section", "power-buttons"]} spacing={8} homogeneous>
      {items.map((item) => (
        <button
          cssClasses={["power-btn"]}
          tooltipText={item.label}
          onClicked={() => {
            setPanelOpen(false)
            execAsync(item.cmd).catch((err) => console.error(err))
          }}
        >
          <image iconName={item.icon} />
        </button>
      ))}
    </box>
  )
}

// --- パネル本体 ---
export default function StatusPanel(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={panelOpen}
      name={`status-panel-${gdkmonitor.get_connector()}`}
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      marginTop={2}
      exclusivity={Astal.Exclusivity.NORMAL}
      layer={Astal.Layer.TOP}
      cssClasses={["StatusPanel"]}
    >
      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["panel-content"]} spacing={0}>
        <MediaSection />
        <VolumeSection />
        <NetworkSection />
        <SystemSection />
        <TemperatureSection />
        <QuickToggles />
        <PowerButtons />
      </box>
    </window>
  )
}
