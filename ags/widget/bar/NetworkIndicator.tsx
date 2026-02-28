import { createBinding } from "ags"
import Network from "gi://AstalNetwork"

export default function NetworkIndicator() {
  const network = Network.get_default()

  const icon = createBinding(network, "primary")(() => {
    if (network.primary === Network.Primary.WIRED) {
      return network.wired?.iconName || "network-wired-symbolic"
    }
    if (network.primary === Network.Primary.WIFI) {
      return network.wifi?.iconName || "network-wireless-symbolic"
    }
    return "network-disconnected-symbolic"
  })

  const tooltip = createBinding(network, "primary")(() => {
    if (network.primary === Network.Primary.WIRED) return "有線接続"
    const wifi = network.wifi
    if (wifi) return wifi.ssid || "WiFi"
    return "未接続"
  })

  return (
    <image cssClasses={["Network"]} iconName={icon} tooltipText={tooltip} />
  )
}
