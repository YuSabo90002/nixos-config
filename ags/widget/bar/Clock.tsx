import { createPoll } from "ags/time"

// モジュールレベルで単一の poll を作成し、全モニターで共有する
const time = createPoll("", 1000, () => {
  const now = new Date()
  return now.toLocaleTimeString("ja-JP", {
    hour: "2-digit",
    minute: "2-digit",
  })
})

export default function Clock() {
  return <label cssClasses={["Clock"]} label={time} />
}
