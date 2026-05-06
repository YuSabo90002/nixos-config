import { createBinding, createState, With } from "ags"
import { Gtk } from "ags/gtk4"
import Bluetooth from "gi://AstalBluetooth"
import Gio from "gi://Gio"

// 非同期メソッドを Promise 化
Gio._promisify(Bluetooth.Device.prototype, "connect_device", "connect_device_finish")
Gio._promisify(Bluetooth.Device.prototype, "disconnect_device", "disconnect_device_finish")

const bt = Bluetooth.get_default()

function deviceIcon(dev: Bluetooth.Device): string {
  const icon = dev.icon
  if (icon && icon.length > 0) return `${icon}-symbolic`
  return "bluetooth-symbolic"
}

function toggleDiscovery() {
  const adapter = bt.adapter
  if (!adapter) return
  try {
    if (adapter.discovering) adapter.stop_discovery()
    else adapter.start_discovery()
  } catch (e) {
    console.error("bluetooth discovery toggle failed:", e)
  }
}

function DeviceRow({ device }: { device: Bluetooth.Device }) {
  const name = createBinding(device, "name")
  const address = createBinding(device, "address")
  const connected = createBinding(device, "connected")
  const paired = createBinding(device, "paired")
  const [busy, setBusy] = createState(false)

  const onPrimaryClick = async () => {
    if (busy.peek()) return
    setBusy(true)
    try {
      if (device.connected) {
        // @ts-expect-error promisified
        await device.disconnect_device()
      } else {
        // @ts-expect-error promisified
        await device.connect_device()
      }
    } catch (e) {
      console.error("bluetooth connect/disconnect failed:", e)
    } finally {
      setBusy(false)
    }
  }

  const onPair = () => {
    try { device.pair() } catch (e) { console.error("pair failed:", e) }
  }

  const onForget = () => {
    const adapter = bt.adapter
    if (!adapter) return
    try { adapter.remove_device(device) } catch (e) { console.error("forget failed:", e) }
  }

  return (
    <box cssClasses={["bt-device"]} spacing={8}>
      <image iconName={deviceIcon(device)} cssClasses={["bt-device-icon"]} />
      <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={2}>
        <label
          halign={Gtk.Align.START}
          cssClasses={["bt-device-name"]}
          label={name((n) => n || "(名前なし)")}
          ellipsize={3}
          maxWidthChars={22}
        />
        <label
          halign={Gtk.Align.START}
          cssClasses={["bt-device-addr"]}
          label={address((a) => a || "")}
        />
      </box>
      <button
        cssClasses={connected((c) => c
          ? ["bt-action-btn", "connected"]
          : ["bt-action-btn"]
        )}
        sensitive={busy((b) => !b)}
        tooltipText={connected((c) => c ? "切断" : "接続")}
        onClicked={onPrimaryClick}
      >
        <image iconName={connected((c) =>
          c ? "network-disconnect-symbolic" : "network-transmit-symbolic"
        )} />
      </button>
      <With value={paired}>
        {(p) => p ? (
          <button
            cssClasses={["bt-action-btn", "danger"]}
            tooltipText="登録解除"
            onClicked={onForget}
          >
            <image iconName="user-trash-symbolic" />
          </button>
        ) : (
          <button
            cssClasses={["bt-action-btn"]}
            tooltipText="ペアリング"
            onClicked={onPair}
          >
            <image iconName="changes-prevent-symbolic" />
          </button>
        )}
      </With>
    </box>
  )
}

function DeviceList() {
  const devices = createBinding(bt, "devices")

  return (
    <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
      <With value={devices}>
        {(ds) => {
          if (!ds || ds.length === 0) {
            return (
              <label
                cssClasses={["panel-status"]}
                halign={Gtk.Align.START}
                label="デバイスが見つかりません"
              />
            )
          }
          // 接続中→ペア済み→新規 の順、各カテゴリ内は名前順
          const score = (d: Bluetooth.Device) =>
            d.connected ? 0 : d.paired ? 1 : 2
          const sorted = [...ds].sort((a, b) => {
            const diff = score(a) - score(b)
            if (diff !== 0) return diff
            return (a.name || "").localeCompare(b.name || "")
          })
          return (
            <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
              {sorted.map((device) => <DeviceRow device={device} />)}
            </box>
          )
        }}
      </With>
    </box>
  )
}

export default function BluetoothSection() {
  const isPowered = createBinding(bt, "isPowered")
  const adapterBinding = createBinding(bt, "adapter")

  return (
    <box cssClasses={["panel-section", "bluetooth-section"]} orientation={Gtk.Orientation.VERTICAL} spacing={8}>
      <box spacing={8}>
        <label cssClasses={["panel-section-icon", "bt-color"]} label="" />
        <label halign={Gtk.Align.START} hexpand label="Bluetooth" />
        <With value={adapterBinding}>
          {(adapter) => {
            if (!adapter) return <box />
            const discovering = createBinding(adapter, "discovering")
            return (
              <button
                cssClasses={discovering((d) =>
                  d ? ["panel-icon-btn", "active"] : ["panel-icon-btn"]
                )}
                sensitive={isPowered}
                tooltipText={discovering((d) => d ? "探索停止" : "探索開始")}
                onClicked={toggleDiscovery}
              >
                <image iconName="view-refresh-symbolic" />
              </button>
            )
          }}
        </With>
        <button
          cssClasses={isPowered((p) => p ? ["toggle-btn", "active"] : ["toggle-btn"])}
          tooltipText={isPowered((p) => p ? "Bluetooth: オン" : "Bluetooth: オフ")}
          onClicked={() => bt.toggle()}
        >
          <image iconName={isPowered((p) =>
            p ? "bluetooth-active-symbolic" : "bluetooth-disabled-symbolic"
          )} />
        </button>
      </box>

      <With value={isPowered}>
        {(powered) => !powered ? (
          <label cssClasses={["panel-status"]} halign={Gtk.Align.START}
                 label="Bluetooth はオフです" />
        ) : <DeviceList />}
      </With>
    </box>
  )
}
