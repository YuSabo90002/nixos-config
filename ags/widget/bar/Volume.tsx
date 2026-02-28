import { createBinding } from "ags"
import { Gtk } from "ags/gtk4"
import Wp from "gi://AstalWp"

export default function Volume() {
  const wp = Wp.get_default()!
  const speaker = wp.audio.defaultSpeaker!

  const icon = createBinding(speaker, "volumeIcon")
  const muted = createBinding(speaker, "mute")

  return (
    <button
      cssClasses={muted((m) => (m ? ["Volume", "muted"] : ["Volume"]))}
      tooltipText={createBinding(speaker, "volume")((v) =>
        `${Math.round(v * 100)}%`,
      )}
      $={(self: Gtk.Button) => {
        const slider = new Gtk.Scale({
          orientation: Gtk.Orientation.HORIZONTAL,
        })
        slider.set_range(0, 1)
        slider.set_increments(0.02, 0.05)
        slider.set_value(speaker.volume)
        slider.set_size_request(150, -1)
        slider.add_css_class("volume-slider")
        slider.set_hexpand(true)

        speaker.connect("notify::volume", () => {
          slider.set_value(speaker.volume)
        })
        slider.connect("value-changed", () => {
          speaker.volume = slider.get_value()
        })

        const label = new Gtk.Label()
        label.add_css_class("volume-label")
        label.set_text(`${Math.round(speaker.volume * 100)}%`)
        label.set_size_request(40, -1)
        speaker.connect("notify::volume", () => {
          label.set_text(`${Math.round(speaker.volume * 100)}%`)
        })

        const muteBtn = new Gtk.Button()
        muteBtn.add_css_class("mute-btn")
        muteBtn.set_child(new Gtk.Image({ iconName: speaker.volumeIcon }))
        speaker.connect("notify::volume-icon", () => {
          (muteBtn.get_child() as Gtk.Image).set_from_icon_name(speaker.volumeIcon)
        })
        muteBtn.connect("clicked", () => {
          speaker.mute = !speaker.mute
        })

        const box = new Gtk.Box({
          orientation: Gtk.Orientation.HORIZONTAL,
          spacing: 8,
        })
        box.append(muteBtn)
        box.append(slider)
        box.append(label)

        const popover = new Gtk.Popover()
        popover.add_css_class("VolumePopup")
        popover.set_has_arrow(false)
        popover.set_child(box)
        popover.set_parent(self)

        self.connect("clicked", () => {
          if (popover.get_visible()) {
            popover.popdown()
          } else {
            popover.popup()
          }
        })
      }}
    >
      <image iconName={icon} />
    </button>
  )
}
