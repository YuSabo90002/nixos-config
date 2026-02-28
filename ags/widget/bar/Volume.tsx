import { createBinding } from "ags"
import Wp from "gi://AstalWp"

export default function Volume() {
  const wp = Wp.get_default()!
  const speaker = wp.audio.defaultSpeaker!

  const icon = createBinding(speaker, "volumeIcon")
  const muted = createBinding(speaker, "mute")

  return (
    <button
      cssClasses={muted((m) => (m ? ["Volume", "muted"] : ["Volume"]))}
      onClicked={() => {
        speaker.mute = !speaker.mute
      }}
      tooltipText={createBinding(speaker, "volume")((v) =>
        `${Math.round(v * 100)}%`,
      )}
    >
      <image iconName={icon} />
    </button>
  )
}
