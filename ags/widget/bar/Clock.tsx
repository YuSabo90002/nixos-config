import { createPoll } from "ags/time"
import { toggleCalendar, calendarIsOpen } from "../CalendarPopup"

// モジュールレベルで単一の poll を作成し、全モニターで共有する
const pad = (n: number) => n.toString().padStart(2, "0")

const time = createPoll("", 1000, () => {
  const now = new Date()
  const y = now.getFullYear()
  const m = pad(now.getMonth() + 1)
  const d = pad(now.getDate())
  const hh = pad(now.getHours())
  const mm = pad(now.getMinutes())
  const ss = pad(now.getSeconds())
  return `${y}/${m}/${d} ${hh}:${mm}:${ss}`
})

export default function Clock({ monitorName }: { monitorName: string }) {
  return (
    <button
      cssClasses={calendarIsOpen((m) => m === monitorName ? ["Clock", "active"] : ["Clock"])}
      onClicked={() => toggleCalendar(monitorName)}
    >
      <label label={time} />
    </button>
  )
}
