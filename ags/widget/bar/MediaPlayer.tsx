import { createBinding, With } from "ags"
import Mpris from "gi://AstalMpris"

export default function MediaPlayer() {
  const mpris = Mpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <box cssClasses={["Media"]}>
      <With value={players}>
        {(ps) => {
          const player = ps[0]
          if (!player) return <box />

          return (
            <button onClicked={() => player.play_pause()}>
              <label
                label={createBinding(player, "title")((t) => {
                  const a = player.artist || ""
                  return a ? `${a} - ${t}` : t || ""
                })}
              />
            </button>
          )
        }}
      </With>
    </box>
  )
}
