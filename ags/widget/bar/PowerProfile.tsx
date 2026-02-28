import { createBinding } from "ags"
import PowerProfiles from "gi://AstalPowerProfiles"

export default function PowerProfile() {
  const pp = PowerProfiles.get_default()
  const profile = createBinding(pp, "activeProfile")

  const icon = profile((p) => {
    switch (p) {
      case "performance":
        return "power-profile-performance-symbolic"
      case "power-saver":
        return "power-profile-power-saver-symbolic"
      default:
        return "power-profile-balanced-symbolic"
    }
  })

  return (
    <button
      cssClasses={profile((p) => ["PowerProfile", p])}
      onClicked={() => {
        const profiles = ["power-saver", "balanced", "performance"]
        const current = profiles.indexOf(pp.activeProfile)
        pp.activeProfile = profiles[(current + 1) % profiles.length]
      }}
      tooltipText={profile((p) => `電力: ${p}`)}
    >
      <image iconName={icon} />
    </button>
  )
}
