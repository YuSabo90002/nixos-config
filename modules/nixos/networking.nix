{ ... }: {
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # ISP が IPv4 のみ契約だが NTT 網内 IPv6 (240b::/20) が RA で流入し、
  # 疎通しない IPv6 先に SYN を撃ち続けてハングするため無効化
  systemd.network.networks."20-wired" = {
    matchConfig.Type = "ether";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
      LinkLocalAddressing = "ipv4";
    };
    dhcpV4Config.RouteMetric = 100;
  };

  systemd.network.networks."25-wireless" = {
    matchConfig.Type = "wlan";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
      LinkLocalAddressing = "ipv4";
    };
    dhcpV4Config.RouteMetric = 600;
  };

  networking.wireless.iwd = {
    enable = true;
    settings = {
      General = {
        EnableNetworkConfiguration = false;
      };
      Settings = {
        AutoConnect = true;
      };
    };
  };

  services.resolved.enable = true;

  networking.firewall.allowedTCPPorts = [ 1420 1421 ];
}
