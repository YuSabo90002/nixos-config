import { Gtk } from "ags/gtk4"
import { createPoll } from "ags/time"
import { readFile } from "ags/file"

let prevIdle = 0
let prevTotal = 0

const HISTORY_LEN = 6
const cpuHistory: number[] = Array(HISTORY_LEN).fill(0)
const memHistory: number[] = Array(HISTORY_LEN).fill(0)

const BLOCKS = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

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

function toSparkline(history: number[]): string {
  return history.map((v) => {
    const idx = Math.min(Math.floor(v / 100 * BLOCKS.length), BLOCKS.length - 1)
    return BLOCKS[Math.max(0, idx)]
  }).join("")
}

function colorClass(value: number): string {
  if (value >= 80) return "critical"
  if (value >= 50) return "warning"
  return "normal"
}

export default function SystemMonitor() {
  const poll = createPoll("", 2000, () => {
    const cpu = getCpuUsage()
    const mem = getMemUsage()
    cpuHistory.shift()
    cpuHistory.push(cpu)
    memHistory.shift()
    memHistory.push(mem)
    return JSON.stringify({ cpu, mem })
  })

  return (
    <box cssClasses={["SystemMonitor"]} spacing={4} tooltipText={poll((v) => {
      try {
        const { cpu, mem } = JSON.parse(v || '{"cpu":0,"mem":0}')
        return `CPU: ${cpu}%\nメモリ: ${mem}%`
      } catch { return "" }
    })}>
      <label cssClasses={["icon", "cpu-icon"]} label={"\uf4bc"} />
      <label cssClasses={poll((v) => {
        try {
          const { cpu } = JSON.parse(v || '{"cpu":0}')
          return ["spark", "cpu", colorClass(cpu)]
        } catch { return ["spark", "cpu"] }
      })} label={poll((v) => {
        try {
          const { cpu } = JSON.parse(v || '{"cpu":0}')
          return toSparkline(cpuHistory)
        } catch { return "" }
      })} />
      <label cssClasses={poll((v) => {
        try {
          const { cpu } = JSON.parse(v || '{"cpu":0}')
          return ["percent", "cpu-pct", colorClass(cpu)]
        } catch { return ["percent", "cpu-pct"] }
      })} label={poll((v) => {
        try {
          const { cpu } = JSON.parse(v || '{"cpu":0}')
          return `${cpu}%`
        } catch { return "0%" }
      })} />
      <label cssClasses={["separator"]} label=" " />
      <label cssClasses={["icon", "mem-icon"]} label={"\uefc5"} />
      <label cssClasses={poll((v) => {
        try {
          const { mem } = JSON.parse(v || '{"mem":0}')
          return ["spark", "mem", colorClass(mem)]
        } catch { return ["spark", "mem"] }
      })} label={poll((v) => {
        try {
          const { mem } = JSON.parse(v || '{"mem":0}')
          return toSparkline(memHistory)
        } catch { return "" }
      })} />
      <label cssClasses={poll((v) => {
        try {
          const { mem } = JSON.parse(v || '{"mem":0}')
          return ["percent", "mem-pct", colorClass(mem)]
        } catch { return ["percent", "mem-pct"] }
      })} label={poll((v) => {
        try {
          const { mem } = JSON.parse(v || '{"mem":0}')
          return `${mem}%`
        } catch { return "0%" }
      })} />
    </box>
  )
}
