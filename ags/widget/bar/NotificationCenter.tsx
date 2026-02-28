import { createBinding } from "ags"
import Notifd from "gi://AstalNotifd"

export default function NotificationCenter() {
  const notifd = Notifd.get_default()
  const notifications = createBinding(notifd, "notifications")

  return (
    <button
      cssClasses={["NotificationCenter"]}
      onClicked={() => {
        notifd.dontDisturb = !notifd.dontDisturb
      }}
      tooltipText={createBinding(notifd, "dontDisturb")((dnd) =>
        dnd ? "通知: オフ" : "通知: オン",
      )}
    >
      <box>
        <image
          iconName={createBinding(notifd, "dontDisturb")((dnd) =>
            dnd
              ? "notifications-disabled-symbolic"
              : "preferences-system-notifications-symbolic",
          )}
        />
        <label
          cssClasses={["count"]}
          visible={notifications((n) => n.length > 0)}
          label={notifications((n) => ` ${n.length}`)}
        />
      </box>
    </button>
  )
}
