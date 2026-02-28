import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { readFile } from "ags/file"

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

function getMemUsage(): number {
  try {
    const meminfo = readFile("/proc/meminfo")
    const lines = meminfo.split("\n")
    const total = parseInt(lines[0].split(/\s+/)[1])
    const available = parseInt(lines[2].split(/\s+/)[1])
    return Math.round(((total - available) / total) * 100)
  } catch {
    return 0
  }
}

export default function SystemMonitor() {
  const cpuLabel = createPoll("0%", 2000, () => `${getCpuUsage()}%`)
  const memLabel = createPoll("0%", 2000, () => `${getMemUsage()}%`)

  return (
    <box cssClasses={["SystemMonitor"]}>
      <label cssClasses={["cpu"]} label={cpuLabel((v) => ` ${v}`)} />
      <label cssClasses={["separator"]} label="|" />
      <label cssClasses={["mem"]} label={memLabel((v) => ` ${v}`)} />
    </box>
  )
}
