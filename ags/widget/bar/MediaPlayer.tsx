import { createBinding } from "ags"
import Mpris from "gi://AstalMpris"

export default function MediaPlayer() {
  const mpris = Mpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <box cssClasses={["Media"]}>
      {players((ps) => {
        const player = ps[0]
        if (!player) return <box />

        const title = createBinding(player, "title")
        const artist = createBinding(player, "artist")

        return (
          <button onClicked={() => player.play_pause()}>
            <label
              label={title((t) => {
                const a = player.artist || ""
                return a ? `${a} - ${t}` : t || ""
              })}
            />
          </button>
        )
      })}
    </box>
  )
}
