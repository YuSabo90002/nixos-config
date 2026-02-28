import { Astal, Gtk } from "ags/gtk4"
import { createBinding } from "ags"
import Notifd from "gi://AstalNotifd"

function Notification({ notification }: { notification: Notifd.Notification }) {
  return (
    <box
      cssClasses={["notification-popup"]}
      orientation={Gtk.Orientation.VERTICAL}
    >
      <box cssClasses={["notification-header"]}>
        <label
          cssClasses={["app-name"]}
          label={notification.appName || "通知"}
          hexpand
          halign={Gtk.Align.START}
        />
        <button
          cssClasses={["close"]}
          onClicked={() => notification.dismiss()}
        >
          <label label="✕" />
        </button>
      </box>
      <label
        cssClasses={["summary"]}
        label={notification.summary}
        halign={Gtk.Align.START}
        wrap
      />
      {notification.body && (
        <label
          cssClasses={["body"]}
          label={notification.body}
          halign={Gtk.Align.START}
          wrap
        />
      )}
      {notification.get_actions().length > 0 && (
        <box cssClasses={["notification-actions"]}>
          {notification.get_actions().map((action) => (
            <button
              label={action.label}
              onClicked={() => notification.invoke(action.id)}
            />
          ))}
        </box>
      )}
    </box>
  )
}

export default function NotificationPopups() {
  const { TOP, RIGHT } = Astal.WindowAnchor
  const notifd = Notifd.get_default()
  const notifications = createBinding(notifd, "notifications")

  return (
    <window
      name="notification-popups"
      anchor={TOP | RIGHT}
      cssClasses={["NotificationPopups"]}
      visible={notifications((n) => n.length > 0)}
    >
      <box orientation={Gtk.Orientation.VERTICAL}>
        {notifications((notifs) =>
          notifs.slice(0, 5).map((n) => <Notification notification={n} />),
        )}
      </box>
    </window>
  )
}
