{ config, lib, ... }:
let
  # IPv6 を抑制するホストでは RA を蹴って IPv4 のみにする。
  # 抑制しないホストは DHCP も RA もそのまま通す。
  v6 =
    if config.my.suppressIPv6 then {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
      LinkLocalAddressing = "ipv4";
    } else {
      DHCP = "yes";
    };
in
{
  options.my.suppressIPv6 = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      IPv6 を全面的に無効化するか。

      自宅回線は ISP が IPv4 のみ契約だが NTT 網内 IPv6 (240b::/20) が RA で流入し、
      疎通しない IPv6 先に SYN を撃ち続けてハングする。据え置き機ではこれを true に
      して回避している。

      持ち出す機体で true にすると、外出先の正常な IPv6 網でも v6 が一切使えなく
      なるため false のままにすること。
    '';
  };

  config = {
    networking.useNetworkd = true;
    systemd.network.enable = true;

    systemd.network.networks."20-wired" = {
      matchConfig.Type = "ether";
      networkConfig = v6;
      dhcpV4Config.RouteMetric = 100;
    };

    systemd.network.networks."25-wireless" = {
      matchConfig.Type = "wlan";
      networkConfig = v6;
      dhcpV4Config.RouteMetric = 600;
    };

    networking.wireless.iwd = {
      enable = true;
      settings = {
        General = {
          # アドレス設定は networkd 側でやるので iwd には触らせない
          EnableNetworkConfiguration = false;
        };
        Settings = {
          AutoConnect = true;
        };
      };
    };

    services.resolved.enable = true;

    networking.firewall.allowedTCPPorts = [ 1420 1421 ];
  };
}
