import { createBinding, createComputed } from "ags"
import Battery from "gi://AstalBattery"

// UPower の既定デバイス。UPower が動いていないホスト (services.upower.enable が
// false のデスクトップ) でも get_default() はオブジェクトを返すので、実際に電池が
// あるかどうかは isPresent で判定する。
// get_default() はシングルトンなので、StatusPanel 側もこれを共有する。
export const battery = Battery.get_default()

// 電池を持たないホストではバー項目ごと出さない。内蔵電池が実行中に生えることは
// ないので、起動時に一度だけ評価すれば足りる。
export const hasBattery = battery !== null && battery.isBattery && battery.isPresent

function levelClass(percent: number): string {
  if (percent <= 15) return "critical"
  if (percent <= 30) return "warning"
  return "normal"
}

// UPower の残り時間は秒。算出できない状態 (AC 接続直後など) では 0 が来るので、
// その場合は時間を出さない。
function formatDuration(seconds: number): string {
  if (seconds <= 0) return ""
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  return h > 0 ? `${h}時間${m}分` : `${m}分`
}

// 充電状態を日本語 1 行にする。充電上限を 80% に設定してあるので、
// 80% 前後で「満充電」ではなく待機状態に落ち着くのが正常な挙動。
export function stateText(
  state: Battery.State,
  timeToFull: number,
  timeToEmpty: number,
): string {
  switch (state) {
    case Battery.State.CHARGING: {
      const t = formatDuration(timeToFull)
      return t ? `充電中 (満充電まで ${t})` : "充電中"
    }
    case Battery.State.DISCHARGING: {
      const t = formatDuration(timeToEmpty)
      return t ? `放電中 (残り ${t})` : "放電中"
    }
    case Battery.State.FULLY_CHARGED:
      return "満充電"
    case Battery.State.EMPTY:
      return "空"
    default:
      // 充電上限に達して充放電が止まっている状態がここに入る
      return "待機"
  }
}

export default function BatteryIndicator() {
  const bat = battery!

  const percentage = createBinding(bat, "percentage")
  const iconName = createBinding(bat, "batteryIconName")
  const state = createBinding(bat, "state")
  const timeToFull = createBinding(bat, "timeToFull")
  const timeToEmpty = createBinding(bat, "timeToEmpty")
  const energyRate = createBinding(bat, "energyRate")

  const tooltip = createComputed(() => {
    const lines = [
      `残量: ${Math.round(percentage() * 100)}%`,
      stateText(state(), timeToFull(), timeToEmpty()),
    ]
    const rate = energyRate()
    if (rate > 0) lines.push(`${rate.toFixed(1)} W`)
    return lines.join("\n")
  })

  return (
    <box cssClasses={["Battery"]} spacing={4} tooltipText={tooltip}>
      {/* アイコンは UPower が充電状態込みで決めた名前 (battery-level-NN-charging-
          symbolic 等) をそのまま使う。Adwaita に全段階が揃っている。 */}
      <image cssClasses={["battery-icon"]} iconName={iconName} />
      <label
        cssClasses={percentage((p) => ["battery-percent", levelClass(Math.round(p * 100))])}
        label={percentage((p) => `${Math.round(p * 100)}%`)}
      />
    </box>
  )
}
