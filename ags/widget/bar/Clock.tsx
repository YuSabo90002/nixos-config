import { createPoll } from "ags/time"

export default function Clock() {
  const time = createPoll("", 1000, () => {
    const now = new Date()
    return now.toLocaleTimeString("ja-JP", {
      hour: "2-digit",
      minute: "2-digit",
    })
  })

  return <label cssClasses={["Clock"]} label={time} />
}
