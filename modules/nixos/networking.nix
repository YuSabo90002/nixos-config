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

  # LAN 機器 (プリンタ等) を `<名前>.local` で引けるようにする。resolved 側の
  # 全体設定と networkd 側のリンク単位設定の両方が yes でないと有効にならない。
  linkConfig = v6 // { MulticastDNS = true; };
in
{
  options.my.suppressIPv6 = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      IPv6 を全面的に無効化するか。

      かつて自宅回線は ISP が IPv4 のみ契約で、NTT 網内 IPv6 (240b::/20) だけが RA で
      流入し、疎通しない IPv6 先に SYN を撃ち続けてハングしていた。据え置き機では
      これを true にして回避していたが、2026-09-07 に IPv6 が開通したので現在は全ホスト false。
      同様の「v6 アドレスは付くが外に抜けない」環境に置く場合に true にする。

      持ち出す機体で true にすると、外出先の正常な IPv6 網でも v6 が一切使えなく
      なるため false のままにすること。
    '';
  };

  config = {
    networking.useNetworkd = true;
    systemd.network.enable = true;

    systemd.network.networks."20-wired" = {
      matchConfig.Type = "ether";
      networkConfig = linkConfig;
      dhcpV4Config.RouteMetric = 100;
    };

    systemd.network.networks."25-wireless" = {
      matchConfig.Type = "wlan";
      networkConfig = linkConfig;
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

    services.resolved = {
      enable = true;
      settings.Resolve.MulticastDNS = true;
    };

    # mDNS の応答はマルチキャストで返ってくるため conntrack で ESTABLISHED 扱いに
    # ならず、5353 を開けないと問い合わせても応答が捨てられる。
    networking.firewall.allowedUDPPorts = [ 5353 ];

    networking.firewall.allowedTCPPorts = [ 1420 1421 ];
  };
}
