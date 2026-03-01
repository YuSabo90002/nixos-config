import { createPoll } from "ags/time"
import { readFile } from "ags/file"
import { exec } from "ags/process"

type NetState = {
  icon: string
  label: string
}

function getNetworkState(): NetState {
  try {
    // 有線チェック
    const ethState = readFile("/sys/class/net/enp8s0/operstate").trim()
    if (ethState === "up") {
      return { icon: "network-wired-symbolic", label: "有線接続" }
    }

    // WiFiチェック
    const wlanState = readFile("/sys/class/net/wlan0/operstate").trim()
    if (wlanState === "up") {
      try {
        const out = exec(["networkctl", "status", "wlan0"])
        const apLine = out.split("\n").find((l) => l.includes("Wi-Fi access point"))
        const match = apLine?.match(/Wi-Fi access point:\s*(.+?)\s*\(/)
        const ssid = match?.[1] || "WiFi"
        return { icon: "network-wireless-symbolic", label: ssid }
      } catch {
        return { icon: "network-wireless-symbolic", label: "WiFi" }
      }
    }

    return { icon: "network-disconnected-symbolic", label: "未接続" }
  } catch {
    return { icon: "network-disconnected-symbolic", label: "不明" }
  }
}

const INIT: NetState = { icon: "network-wireless-symbolic", label: "" }

// モジュールレベルで単一の poll を作成し、全モニターで共有する
const poll = createPoll(JSON.stringify(INIT), 5000, () => JSON.stringify(getNetworkState()))

export default function NetworkIndicator() {

  return (
    <box cssClasses={["Network"]} spacing={4}>
      <image iconName={poll((v) => {
        try { return JSON.parse(v).icon } catch { return "network-disconnected-symbolic" }
      })} />
      <label label={poll((v) => {
        try { return JSON.parse(v).label } catch { return "" }
      })} />
    </box>
  )
}
